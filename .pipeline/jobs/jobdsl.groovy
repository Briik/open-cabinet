githubRepoUrl = 'git@github.com:pattyb0y/open-cabinet.git'

def environment = "${jenkinsEnvironment}"
if (!environment)
{
  environment = "development"  
}

pipelines =  [
  'Build Sandbox':[
    'commit':[
      'poll-version-control',
      'run-static-analysis',
      'run-unit-tests',
      'run-local-acceptance-tests'
    ],
    'acceptance':[
      'create-system-image',
      'create-acceptance-environment',
      'run-infrastructure-tests',
      'run-acceptance-tests',
      'promote-ami'
    ],
    'dev-duction':[
      'blue-green-deploy-dev-environment',
      'run-smoke-test'
    ]
  ]
]
appName = 'sandbox'

//////////////////////////////////////////////////////////////////////////
// Utility methods
//////////////////////////////////////////////////////////////////////////
jobRegistry = [:]

def allStepNameStageNamePairsForPipeline(stages) {
  def stepNames = []

  stages.each { stage, steps ->
    steps.each { step ->
      stepNames.add([step, stage])
    }
  }
  return stepNames
}

def eachPair(items, Closure perPairAction) {
  [*items, null].collate(2, 1, false).each(perPairAction)
}


def defineJob(name, Closure jobDefinition) {
  createdJob = job(name, jobDefinition)
  jobRegistry[name] = createdJob
  return createdJob
}

def fullJobName(stepName) {
  return "${appName}-${stepName}-dsl"
}

//////////////////////////////////////////////////////////////////////////
// Actual Job definitions
//////////////////////////////////////////////////////////////////////////

nestedView(appName) {
  views {
    deliveryPipelineView("Build ${appName}") {
      name("Build ${appName}")

      pipelineInstances(10)
      showAggregatedPipeline(false)
      columns(1)
      updateInterval(2)
      showAvatars(false)
      showChangeLog(false)
      pipelines {
        component("${appName} build pipeline", fullJobName('poll-version-control'))
      }
    }
  }
}


defineJob("base-${appName}-job-dsl") {
  scm {
    git {
      remote {
        url(githubRepoUrl)
      }
      branch('$GIT_SHA')
      createTag(false)
    }
  }

  wrappers {
    rvm("2.2.2@${appName}")
    colorizeOutput('xterm')
  }

  publishers {
    extendedEmail('patrick.rasche@excella.com',
                  "\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS!",
                  """\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS:

        Check console output at \$BUILD_URL to view the results.""") {
      trigger('Failure')
      trigger('Fixed')
    }
  }
}

defineJob(fullJobName('poll-version-control')) {
  using "base-${appName}-job-dsl"

  parameters {
    stringParam('branch', 'master', 'branch to override master with')
    stringParam("revision", null, "The sandbox revision to build an environment with. If empty, the latest revision will be used.")
  }

  scm {
    git {
      remote {
        url(githubRepoUrl)
      }
      branch('${branch}')
      createTag(false)

      configure { git ->
        (git / 'extensions' / 'hudson.plugins.git.extensions.impl.PathRestriction' / 'excludedRegions').setValue("README.md\n.pipeline/jobs/.*")
      }
    }
  }

  if (environment.equalsIgnoreCase("development")) {
    triggers {
      scm("* * * * *")
    }
  }
  
}

defineJob(fullJobName('run-static-analysis')) {
  using "base-${appName}-job-dsl"

  parameters {
    stringParam('pipeline_instance_id')
  }

  publishers {
    configure { job ->
      job / 'publishers' / 'hudson.plugins.brakeman.BrakemanPublisher' {
        pluginName '[BRAKEMAN]'
        defaultEncoding 'UTF-8'
        canRunOnFailed false
        useDeltaValues false
        shouldDetectModules false
        dontComputeNew true
        outputFile 'brakeman-output.tabs'
      }
    }

    publishHtml {
      report('tmp/rubycritic/', 'Ruby Critic', 'overview.html', true)
    }
  }
}

defineJob(fullJobName('run-unit-tests')) {
  using "base-${appName}-job-dsl"

  parameters {
    stringParam('pipeline_instance_id')
  }

  publishers {
    configure { job ->
      job / 'publishers' / 'hudson.plugins.rubyMetrics.rcov.RcovPublisher' {
        reportDir 'coverage/rcov'
        targets {
          'hudson.plugins.rubyMetrics.rcov.model.MetricTarget' {
            metric 'TOTAL_COVERAGE'
            healthy '80'
            unhealthy '0'
            unstable '0'
          }
          'hudson.plugins.rubyMetrics.rcov.model.MetricTarget' {
            metric 'CODE_COVERAGE'
            healthy '80'
            unhealthy '0'
            unstable '0'
          }
        }
      }
    }
  }
}

defineJob(fullJobName('create-acceptance-environment')) {
  using "base-${appName}-job-dsl"

  parameters {
    stringParam('pipeline_instance_id')
  }

  publishers {
    configure { job ->
      job / 'publishers' / 'hudson.plugins.parameterizedtrigger.BuildTrigger' {
        configs {
          'hudson.plugins.parameterizedtrigger.BuildTriggerConfig' {
            configs {
              'hudson.plugins.parameterizedtrigger.CurrentBuildParameters' {}
            }
            projects 'deploy-app-download-failed-log-trigger-dsl'
            condition 'FAILED'
            triggerWithNoParameters false
          }
        }
      }
    }
  }
}



defineJob(fullJobName('run-local-acceptance-tests')) {
  using "base-${appName}-job-dsl"

  parameters {
    stringParam('pipeline_instance_id')
  }

  publishers {
    configure { job ->
      job / 'publishers' / 'net.masterthought.jenkins.CucumberReportPublisher' {
        jsonReportDirectory "test_result"
        pluginUrlPath ""
        skippedFails false
        undefinedFails false
        noFlashCharts false
        (job / 'publishers' / 'net.masterthought.jenkins.CucumberReportPublisher').@plugin = "cucumber-reports@0.0.23"
      }
    }
  }
}

defineJob(fullJobName('run-infrastructure-tests')) {
  using "base-${appName}-job-dsl"

  parameters {
    stringParam('pipeline_instance_id')
  }

  publishers {
    publishHtml {
      report('.pipeline/config', 'Infrastructure Test Results', 'serverspec_aws_infra_results.html', true)
    }
  }
}


stepsWithDefaultDefintions = [
  'create-system-image',
  'run-acceptance-tests',
  'blue-green-deploy-dev-environment',
  'run-smoke-test',
  'promote-ami'
]

stepsWithDefaultDefintions.each { stepName ->
  defineJob(fullJobName(stepName)) {
    using "base-${appName}-job-dsl"

    parameters {
      stringParam('pipeline_instance_id')
    }
  }
}

pipelines.each { pipeline, stages ->
  def allStepNameStageNamePairs = allStepNameStageNamePairsForPipeline(stages)

  //pair of pairs to be clear
  eachPair(allStepNameStageNamePairs) { currentStepStagePair, nextStepStagePair ->
    stepName = currentStepStagePair[0]
    stageName = currentStepStagePair[1]
    nextStepName = nextStepStagePair == null ? null : nextStepStagePair[0]

    currentJob = jobRegistry[fullJobName(stepName)]

    currentJob.deliveryPipelineConfiguration(stageName, stepName)

    currentJob.steps {
      shell(".pipeline/${stepName}.sh")

      if (nextStepName != null) {
        downstreamParameterized {
          trigger (fullJobName(nextStepName), 'ALWAYS') {
            currentBuild()
            propertiesFile('environment.txt')
          }
        }
      }
    }
  }
}
