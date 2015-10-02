CloudFormation {
	Description 'Creates an RDS DBInstance for Open-Cabinet in an existing Virtual Private Cloud (VPC).'
    
    Parameter('VpcId') {
        String
        Description 'VpcId of your existing Virtual Private Cloud (VPC)'
    }

    Parameter('DBSubnetGroupID') {
        String
        Description 'The list of SubnetIds, for at least two Availability Zones in the region in your Virtual Private Cloud (VPC)'
    }

    Parameter('DBInstanceIdentifier') {
        Description 'The database identifier'
        String
    }

    Parameter('DBSnapshotIdentifier') {
        Description 'DB snapshot to restore from'
        String
        Default ''
    }

    Parameter('DBName') {
        Description 'The database name.  Must be empty when DBSnapshotIdentifier is provided.'
        String
        MinLength 0
        MaxLength	 64
        Default ''
    }

    Parameter('DBUsername') {
        NoEcho true
        Description 'The database username'
        String
        MinLength 1
        MaxLength 16
        AllowedPattern '[a-zA-Z][a-zA-Z0-9]*'
        ConstraintDescription 'must begin with a letter and contain only alphanumeric characters.'
    }

    Parameter('DBPassword') {
        NoEcho true
        Description 'The database password'
        String
        MinLength 8
        MaxLength 41
        AllowedPattern '[a-zA-Z0-9]*'
        ConstraintDescription 'must contain only alphanumeric characters.'
    }

    Parameter('DBClass') {
        Description 'Database instance class'
        String
        ConstraintDescription 'must select a valid database instance type.'
    }

    Parameter('DBAllocatedStorage') {
        Description 'The size of the database (Gb)'
        Type "Number"
        MinValue 5 
        MaxValue 1024
        ConstraintDescription 'must be between 5 and 1024Gb.'
    }

    Parameter('DBParameterGroupName') {
        Description 'DB parameter group name'
        String
        Default 'default.postgres9.4'
    }
   
	EC2_SecurityGroup('OpenCabinetRDSSecurityGroup') {
	  GroupDescription 'RDS DB Instance access'
	  VpcId Ref('VpcId')

	  SecurityGroupIngress {
	    IpProtocol 'tcp'
	    FromPort '5432'
	    ToPort '5432'
	    CidrIp '10.193.0.0/16'
	  }
	}

   RDS_DBInstance('OpenCabinetDB') {
            DBInstanceIdentifier Ref('DBInstanceIdentifier')
            DBSnapshotIdentifier Ref('DBSnapshotIdentifier')
            DBName Ref('DBName')
            AllocatedStorage Ref('DBAllocatedStorage')
            DBInstanceClass Ref('DBClass')
            Engine 'postgres'
            EngineVersion '9.4'
            MasterUsername Ref('DBUsername')
            MasterUserPassword Ref('DBPassword')
            DBSubnetGroupName Ref('DBSubnetGroupID')
            VPCSecurityGroups [ Ref('OpenCabinetRDSSecurityGroup') ]
            DBParameterGroupName Ref('DBParameterGroupName')
            Property 'StorageEncrypted', true
            Tags [      
            	Tag {
			        Key 'Client'
			        Value 'myUSCIS'
			    }
            ]
	}	
}