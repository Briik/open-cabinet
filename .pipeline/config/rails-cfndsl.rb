CloudFormation {
  Description 'Contains configuration information to automatically build a Sandbox Rails server.'

  Parameter('ELBSubnets') {
    Type 'CommaDelimitedList'
    Description 'The subnet IDs the ELB should be attached to.'
  }

  Parameter('ASGSubnets') {
    Type 'CommaDelimitedList'
    Description 'The subnet IDs the ELB should direct traffic to.'
  }

  Parameter('ASGSubnetAZs') {
    Type 'CommaDelimitedList'
    Description 'The availability zones where the ELB should direct traffic to.'
  }

  # Parameter('ELBLoggingBucket') {
  #   String
  #   Description 'The VPC to deploy the instance to'
  #   Default 'myuscis-elb-logs'
  # }

  #instance parmeters
  Parameter('imageId') {
    String
    NoEcho true
    Description 'The AMI ID to use to build this instance'
  }

  Parameter('vpcCidr') {
    String
    Description 'The VPC Cidr mask - used for locking security rules'
  }

  Parameter('secretKeyBase') {
    String

    NoEcho true
    Description 'The Rails secret key seed'
  }

  Parameter('authUser') {
    String
    Default 'myuscis'
    Description 'The username that the basic authentication on the website will use'
  }

  Parameter('authPass') {
    String

    Default 'myuscis'
    NoEcho true
    Description 'The password that the basic authentication on the website will use'
  }

  Parameter('uspsApiKey') {
    String

    NoEcho true
    Description 'The Api key for USPS'
    Default ''
  }

  Parameter('databaseHost') {
    String
    Description 'The location of the PostgreSQL DB that Explore My Options will use'
  }

  Parameter('databaseUser') {
    String
    Default 'sandbox'
    Description 'The database user'
  }

  Parameter('databasePass') {
    String

    NoEcho true
    Description 'The database password'
  }

  # Parameter('databaseName') {
  #   String
  #
  #   Default 'sandbox'
  #   Description 'The database name'
  # }

  Parameter('InstanceKeyPair') {
    String

    Default 'jonnysywulak-us-west-2'
    Description 'The ssh key you want to associate with the instance'
  }

  Parameter('VpcId') {
    String
    Description 'The VPC to deploy the instance to'
    Default 'vpc-82b47fe6'
  }

  Parameter('certPass') {
    String

    NoEcho true
    Description 'The password to decrypt the SSL certificate and key'
  }

  Parameter('callbackUrl') {
    String
    Description 'The URL SAML authentications will point back to'
  }

  Parameter('samlEndpointUrl') {
    String
    Description 'The URL SAML authentications will point to'
  }

  Parameter('samlPassword') {
    String
    NoEcho true
    Description 'The password to decrypt the SAML certs'
  }

  Parameter('samlIdpCertObject') {
    String
    Description 'The name of the encrypted identity provider certificate'
  }

  Parameter('samlCertObject') {
    String
    Description 'The name of the encrypted saml certificate'
  }

  Parameter('samlPrivateKey') {
    String
    Description 'The name of the encrypted saml private key'
  }

  Parameter('portalEndpoint') {
    String
    Description 'The url of the portal endpoint'
    Default ''
  }

  Parameter('elisPassword') {
    String
    NoEcho true
    Description 'Elis integration password'
    Default ''
  }

  Parameter('KeyArn') {
    String
    Description 'kms key alias to decrypt with'
  }

 Parameter('sfEndpoint') {
      String
      Description 'The Sales Force endpoint'
  }

  Parameter('sfClientId') {
      String
      NoEcho true
      Description 'The name of the value of the Sales Force client Id'
  }

  Parameter('sfClientSecret') {
      String
      NoEcho true
      Description 'The name of the value of the Sales Force client secret'
  }

  Parameter('sfUserName') {
      String
      NoEcho true
      Description 'The name of the value of the Sales Force client username'
  }

  Parameter('sfPassword') {
      String
      NoEcho true
      Description 'The name of the value of the Sales Force client password'
  }

  CloudFormation_WaitConditionHandle('WaitForInstanceWaitHandle')

  CloudFormation_WaitCondition('WaitForInstance') {
    DependsOn 'AutoScalingGroup'
    Handle Ref('WaitForInstanceWaitHandle')
    Timeout '2700'
  }

  def define_elb
    the_whole_world = '0.0.0.0/0'

    EC2_SecurityGroup('ELBSecurityGroup') {
      GroupDescription 'Allow inbound access to the ELB'
      VpcId Ref('VpcId')

      SecurityGroupIngress {
        IpProtocol 'tcp'
        FromPort '80'
        ToPort '80'
        CidrIp the_whole_world
      }

      SecurityGroupIngress {
        IpProtocol 'tcp'
        FromPort '443'
        ToPort '443'
        CidrIp the_whole_world
      }

      SecurityGroupEgress {
        IpProtocol 'tcp'
        FromPort '80'
        ToPort '80'
        CidrIp the_whole_world
      }

      SecurityGroupEgress {
        IpProtocol 'tcp'
        FromPort '443'
        ToPort '443'
        CidrIp the_whole_world
      }
    }

    ElasticLoadBalancing_LoadBalancer('LoadBalancer') {
      SecurityGroups [ Ref('ELBSecurityGroup')]
      Subnets Ref('ELBSubnets')
      CrossZone false
      Listeners [
        Listener {
          LoadBalancerPort '80'
          InstancePort '80'
          Protocol 'TCP'
        },
        Listener {
          LoadBalancerPort '443'
          InstancePort '443'
          InstanceProtocol 'SSL'
          SSLCertificateId FnJoin('', ['arn:aws:iam::', Ref('AWS::AccountId'), ':server-certificate/jenkins-cert'] )
          Protocol 'SSL'
        }
      ]

      HealthCheck {
        Target 'HTTPS:443/is_it_up'
        HealthyThreshold '3'
        UnhealthyThreshold '5'
        Interval '90'
        Timeout '60'
      }

      ConnectionDrainingPolicy {
        Enabled true
        Timeout 300
      }

      Scheme 'internal'

      # Property 'AccessLoggingPolicy', {
      #   'Enabled' => true,
      #   'EmitInterval' => 60,
      #   'S3BucketName' => Ref('ELBLoggingBucket'),
      #   'S3BucketPrefix' => Ref('AWS::StackName')
      # }

      Property 'Tags', [
        {
          'Key' => 'client',
          'Value' => 'myuscis'
        }
      ]
    }
  end

  def define_iam
    assume_role_policy_document_hash = {
      'Statement' => [
        {
          'Effect' => 'Allow',
          'Principal' => {
            'Service' => %w{ec2.amazonaws.com}
          },
          'Action' => [
            'sts:AssumeRole'
          ]
        }
      ]
    }

    IAM_Role('RailsInstanceRole') {
      AssumeRolePolicyDocument assume_role_policy_document_hash

      Path '/'

      Policies [
        {
          'PolicyName' => 'Sandbox-policy',
          'PolicyDocument' => {
            'Statement' => [
              {
                'Effect' => 'Allow',
                'Action' => %w{
                 s3:GetObject
                 s3:PutObject
                 s3:DeleteObject
                 cloudwatch:GetMetricStatistics
                 cloudwatch:ListMetrics
                 cloudwatch:PutMetricData
                 ec2:DescribeTags
               },
               'Resource' => '*'
              },
              {
                'Effect' => 'Allow',
                'Action' => %w{
                  kms:Decrypt
                  kms:Get*
                  kms:List*
                },
                'Resource' => Ref('KeyArn')
              }
            ]
          }
        }
      ]
    }

    IAM_InstanceProfile('RailsInstanceProfile') {
      Path '/'
      Roles [ Ref('RailsInstanceRole') ]
    }
  end

  define_elb

  define_iam

  EC2_SecurityGroup('SandboxSecurityGroup') {
    GroupDescription 'Enable SSH and HTTP Access'
    VpcId Ref('VpcId')

    SecurityGroupIngress {
      IpProtocol 'tcp'
      FromPort '22'
      ToPort '22'
      CidrIp Ref('vpcCidr')
    }

    SecurityGroupIngress {
      IpProtocol 'tcp'
      FromPort '80'
      ToPort '80'
      CidrIp Ref('vpcCidr')
    }

    SecurityGroupIngress {
      IpProtocol 'tcp'
      FromPort '443'
      ToPort '443'
      CidrIp Ref('vpcCidr')
    }
  }

  AutoScaling_AutoScalingGroup('AutoScalingGroup') {
    AvailabilityZones Ref('ASGSubnetAZs')
    LaunchConfigurationName Ref('LaunchConfig')
    LoadBalancerNames [ Ref('LoadBalancer') ]
    HealthCheckGracePeriod 300
    HealthCheckType 'ELB'
    MaxSize 1
    MinSize 1
    Tags [
      Tag {
        Key 'Name'
        Value Ref('AWS::StackName')
        PropagateAtLaunch true
      },
      Tag {
        Key 'Client'
        Value 'myUSCIS'
        PropagateAtLaunch true
      }
    ]
    VPCZoneIdentifier Ref('ASGSubnets')

    # Property 'NotificationConfiguration', {
    #   'NotificationTypes' => %w{autoscaling:EC2_INSTANCE_LAUNCH},
    #   'TopicARN' => Ref('notificationTopic')
    # }
  }

  AutoScaling_ScalingPolicy('ScaleUpPolicy') {
    AutoScalingGroupName Ref('AutoScalingGroup')
    AdjustmentType 'ChangeInCapacity'
    Cooldown '300'
    ScalingAdjustment '6'
  }

  AutoScaling_ScalingPolicy('ScaleDownPolicy') {
    AutoScalingGroupName Ref('AutoScalingGroup')
    AdjustmentType 'ChangeInCapacity'
    Cooldown '600'
    ScalingAdjustment '-1'
  }

  CloudWatch_Alarm('CPUAlarmHigh') {
    AlarmDescription 'Scale-up if CPU > 40% for 5 minutes'
    MetricName 'CPUUtilization'
    Namespace 'AWS/EC2'
    Statistic 'Average'
    Period '300'
    EvaluationPeriods '1'
    Threshold '40'
    AlarmActions [ Ref('ScaleUpPolicy') ]
    Dimensions [
       Dimension {
        Name 'AutoScalingGroupName'
        Value Ref('AutoScalingGroup')
      }
    ]
    ComparisonOperator 'GreaterThanThreshold'
  }

  CloudWatch_Alarm('CPUAlarmLow') {
    AlarmDescription 'Scale-down if CPU < 30% for 15 minutes'
    MetricName 'CPUUtilization'
    Namespace 'AWS/EC2'
    Statistic 'Average'
    Period '900'
    EvaluationPeriods '2'
    Threshold '30'
    AlarmActions [ Ref('ScaleDownPolicy') ]
    Dimensions [
                 Dimension {
        Name 'AutoScalingGroupName'
        Value Ref('AutoScalingGroup')
      }
    ]
    ComparisonOperator 'LessThanThreshold'
  }

  AutoScaling_LaunchConfiguration('LaunchConfig') {
    AssociatePublicIpAddress false
    IamInstanceProfile Ref('RailsInstanceProfile')
    ImageId Ref('imageId')
    InstanceType 'm3.medium'
    KeyName Ref('InstanceKeyPair')
    SecurityGroups [Ref('SandboxSecurityGroup')]

    export_all_vars = [
      "#!/bin/bash -x\n",
      'export certPass=\'', Ref('certPass'), "'\n",
      'export samlPassword=\'', Ref('samlPassword'), "'\n",
      'export samlIdpCertObject=\'', Ref('samlIdpCertObject'), "'\n",
      'export samlCertObject=\'', Ref('samlCertObject'), "'\n",
      'export samlPrivateKey=\'', Ref('samlPrivateKey'), "'\n",
      'export callback_url=\'', Ref('callbackUrl'), "'\n",
      'export basic_auth_username=\'', Ref('authUser'), "'\n",
      'export basic_auth_password=\'', Ref('authPass'), "'\n",
      'export secret_key_base=\'', Ref('secretKeyBase'), "'\n",
      'export usps_api_key=\'', Ref('uspsApiKey'), "'\n",
      'export saml_endpoint_url=\'', Ref('samlEndpointUrl'), "'\n",
      'export portal_endpoint=\'', Ref('portalEndpoint'), "'\n",
      'export elis_password=\'', Ref('elisPassword'), "'\n",
      'export database_host=\'', Ref('databaseHost'), "'\n",
      'export database_username=\'', Ref('databaseUser'), "'\n",
      'export database_password=\'', Ref('databasePass'), "'\n",
      'export sales_force_endpoint=\'', Ref('sfEndpoint'), "'\n",
      'export sales_force_client_id=\'', Ref('sfClientId'), "'\n",
      'export sales_force_client_secret=\'', Ref('sfClientSecret'), "'\n",
      'export sales_force_user_name=\'', Ref('sfUserName'), "'\n",
      'export sales_force_password=\'', Ref('sfPassword'), "'\n"
    ]

    signal_completion = [
      "curl -X PUT -H 'Content-Type:' --data-binary @/userdata/status.json '", Ref('WaitForInstanceWaitHandle'), "'\n"
    ]

    def read_bash_script_as_userdata(path_name)
      IO.read(path_name).split("\n").map { |line| line + "\n"}
    end

    UserData FnBase64(FnJoin('',
                             export_all_vars + read_bash_script_as_userdata('.pipeline/config/rails-userdata.sh') + signal_completion))
  }
}

