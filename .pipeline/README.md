Pipeline Overview
=================
The pipeline consists of three real "stages" in sequence.  As the success criteria for each stage are met,
execution continues on to the next stage.  Each stage is constituted by "steps" which manifest as Jenkins jobs.

Commit
------
The commit stage is meant to provide super fast, but possibly less realistic feedback on the results of a change
 to the underlying software system.  This includes static analysis on the code and unit and acceptance tests running local on
 the Jenkins instance (instead of running against a live realistic system).

Acceptance
----------
The acceptance stage involves spinning up a real environment in EC2 that looks very much like production, if not
exactly like it (constraints may apply of course).  The point for this environment is to allow very realistic testing
before promoting to production, although at the cost that it is more expensive in time to create a realistic environment.
  
This pipeline doesn't make an AMI or deal with "permanent" ELBs like other myuscis pipelines as it is just intended
for "sandbox" development.  Therefore, the acceptance environment is the full "production" environment including
a fresh ELB, ASG and EC2 instance to deploy the app to.

After acceptance tests pass against this new environment, the environment is promoted to be the new production - or "dev-duction".

Dev-Duction
-----------
This is basically "production" as far as the sandbox is concerned.  Dev-duction is production for the "dev" environment
which is a persistent, shared environment.  The underlying infrastructure is immutable and disposible, but the common 
domain name makes it appear persistent, and is shared among the dev team.

This stage has only the one step which is to promote the "acceptance" environment that passed all its tests and 
make it the new dev-duction.  The promotion is done by pointing to the domain name development.sandbox.myuscispilot.com
to the new ELB. 

The old CloudFormation stack representing the previous dev-duction environment will linger until the "zombie sweeper"
destroys it later in the day.

Infrastructure and Node Configuration Overview
==============================================
Infrastructure
--------------
The infrastructure consists of an ELB and an 1/1/1 AutoScalingGroup with a medium instance.

This is constructed through a CloudFormation template *but* the template is specified in Ruby
using the cfndsl gem/language.   

This allows for a much more succinct specification, looping, functions and
comments, etc. like a real language (vs. JSON).  Additionally, the "user data" can be broken off
as a separate, more readable bash file and then merged into the template.  See [.pipeline/config/rails-cfndsl.rb]. 

Each time the acceptance environment is created, the cfndsl processes this ruby code and spits out a JSON that is
 passed onto AWS just like a normal CloudFormation template.

The syntax is fairly straightforward, but for more information see: https://github.com/stevenjack/cfndsl


Node Configuration
------------------
In addition to the sandbox application, and the basic myuscis configurations like https_ssl, new relic and saml_certs,
a PostgreSQL 9.4 database is installed locally on the EC2 instance.

This server is only bound on the localhost interface.  No provisions are made for "managing" this database
such as backup or high availability.

Additionally, a variety of "secrets" are laid down that may not yet be in use, but are there to be used:

 * callback_url
 * basic_auth_username
 * basic_auth_password
 * usps_api_key
 * saml_endpoint_url
 * portal_endpoint
 * elis_password


Pipeline Construction
=====================
The stages and steps of the pipeline are specified using the "job dsl" specification language.  This specification
 is available at [jobs/jobdsl.groovy].  For a reference on the job dsl language, please see: https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference
 
The structure of this jobdsl.groovy is different from the other pipelines like wizard.  Instead of one job definition looped over
with a variety of conditionals to accommodate the variances of all the steps, each step/job has its own definition but
inherits common configuration from a base job.  The intention here is to still have the common configuration in one place
but provide a more declarative specification for the jobs without the cyclomatic complexity induced by the
conditionals (see the jobsdl.groovy for the overall self service job).
 
Add a step
----------
1. Add a call to defineJob for the new step, inheriting from the base job.  Include whatever makes the step/job unique here.

        defineJob(fullJobName('some-new-step-name')) {
          using "base-${appName}-job-dsl"
        
          parameters {
            stringParam("revision", null, "The sandbox revision to build an environment with. If empty, the latest revision will be used.")
          }
        
          publishers {
            //my fancy cool report 
          }
        }
   
   The call to defineJob has the side effect of registering this created job in a registry that is used when the job/steps
   are strung together in order (by name).
  
2.  Add the _step name_ (not the job name) to the `pipelines` data structure  

Change common configuration
---------------------------
Update the configuration for the job "base-${appName}-job-dsl" and run the job seed.  It will percolate to all the 
jobs in the pipeline.

Adding a new pipeline or view
-----------------------------
There is a nestedView defined for sandbox overall.  As new pipelines are added, or just new collection of jobs
that should be viewed together, add a new view under the code:

    nestedView(appName) {
      views {

Step Execution Logic
--------------------
Each step has a bash script under .pipeline that encapsulates its logic.  

The step scripts all source in common-bash-functions.sh in an effort to reduce some of the replication in the code.
In bash, reuse is not all that ideal, but hopefully these functions are simple enough to avoid any unpleasantries
with reducing the replication.  For more on bash functions, see: http://tldp.org/LDP/abs/html/functions.html

Theoretically these scripts can run in isolation on your dev box to test them before pushing them into the pipeline.
There may be some interactions with the configstore/inventory or other systems that could cause trouble there, but
that aside, recreating the jenkins user environment on your local box should allow running these scripts locally. 
So, set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in the local environment, and then run "env" as the jenkins user
on the Jenkins box and scrape the environment variables for the config store, its password etc.

Parameterization of the Infrastructure
--------------------------------------
At the bottom of the food chain, Chef cookbooks are responsible for converging the configuration of a given node.
Just above that, CloudFormation builds the infrastructure in AWS including an EC2 instance upon which Chef is bootstrapped
and executed.  These build steps are above that and potentially drop a huge load of parameters into the template 
which affects the infrastructure, and then some of those get pushed down through to the user data of the template to
affect the behavior of the cookbooks.

Up here in the step execution logic, those values can come from several sources:

 * the vpc "inventory" - configuration that is mostly static per VPC or has been generated by other processes (AMI ids etc)
 * the pipeline property store - configuration that has been generated by previous steps in the pipeline
 * the bash environment which includes injected Jenkins job build parameters

Sandbox Cookbooks
=================
All the tooling should be in place to support a cookbook development approach that is:

 * Test-Driven with serverspec
 * Local through the use of test-kitchen with a Vagrant/VirtualBox driver
 
There is a bit of a learning curve, but it is believed this approach ultimately leads 
to cookbooks that are better tested in isolation leading to better quality.  

Additionally, the local development should enable faster development vs. making a change and hoping for the best
as the cookbook is pulled down from an EC2 instance made from a CloudFormation template.... 10 minutes later.

Prequisites
-----------
Test-kitchen, vagrant and VirtualBox should be installed in the local develoment environment.

See: https://github.com/test-kitchen/test-kitchen/wiki/Getting-Started for more instructions.

Process Example
---------------
We need to change the sandbox cookbook to include adding a file with certain content for the foobar service.

1. The first step is to think about WHAT the change is, and how to describe it.  Then using serverspec "resources", 
   capture that description.

   Under cookbooks/sandbox/test/integration/defualt/serverspec, add a file for the new "spec" named for what is under test: foobar_spec.rb

    describe file('/etc/foobar_config') do
      it { should be_file }
      it { should be_mode 0644 }
      it { should be_owned_by 'foo' }
      it { should be_grouped_into 'foogroup' }
      it { should contain ('configitem=value') }
    end
      
2. The next step is to run the test and ensure it fails.  If it succeeds, either the test is wrong, or for some reason
   the configuration already exists
   
         kitchen test

3. Fix up the cookbook to lay down the proper file.  Run the tests again:
     
         kitchen verify
         
4. If success, then move on, otherwise figure out whether the test our the code under test is incorrect.
         
         
     
