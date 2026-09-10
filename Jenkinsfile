pipeline {
    // 1. Agent - Defines where the pipeline or specific stages will execute
    agent {
        node {
            label 'linux-runner'
            customWorkspace '/var/jenkins/workspaces/complete-demo'
        }
    }

    // 2. Environment - Defines global environment variables available to all stages
    environment {
        GLOBAL_APP_NAME = 'MyEnterpriseApp'
        DEPLOY_TARGET   = 'staging'
        CREDENTIALS_ID  = credentials('my-secure-api-token') // Injects credentials safely
    }

    // 3. Options - Configuration settings specific to the pipeline itself
    options {
        timeout(time: 1, unit: 'HOURS')      // Aborts the build if it takes longer than 1 hour
        retry(2)                             // Retries the entire pipeline up to 2 times on failure
        timestamps()                         // Prepends console output with the time it occurred
        disableConcurrentBuilds()            // Prevents multiple builds of this job from running simultaneously
        buildDiscarder(logRotator(numToKeepStr: '10')) // Keeps only the last 10 build records
    }

    // 4. Parameters - User inputs requested when clicking "Build with Parameters"
    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Code branch to build')
        booleanParam(name: 'RUN_INTEGRATION_TESTS', defaultValue: true, description: 'Check to execute integration tests')
        choice(name: 'LOG_LEVEL', choices: ['INFO', 'DEBUG', 'WARN', 'ERROR'], description: 'Console logging level')
        password(name: 'RELEASE_SECRET', description: 'Secret key required for automated releases')
    }

    // 5. Triggers - Automated ways to kick off the pipeline
    triggers {
        cron('H H(0-2) * * 1-5')             // Runs periodically (e.g., every weekday night between 12 AM and 2 AM)
        pollSCM('H/15 * * * *')              // Polls source control for changes every 15 minutes
        upstream(upstreamProjects: 'Pre-Requisite-Job', threshold: hudson.model.Result.SUCCESS) // Triggers if another job succeeds
    }

    // 6. Tools - Automatically installs and adds specified tools to the PATH
    tools {
        maven 'Maven_3.9.x'
        jdk 'Java_17'
        nodejs 'Node_18'
    }

    // 7. Stages - The main container for all the work defined in the pipeline
    stages {
        
        stage('Initialize & Validate') {
            steps {
                echo "Starting build for ${env.GLOBAL_APP_NAME} on branch ${params.BRANCH_NAME}"
                sh 'mvn --version'
                sh 'node --version'
            }
        }

        // Parallel execution structure
        stage('Parallel Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo "Running unit test suites..."
                        sh 'mvn test'
                    }
                }
                stage('Static Code Analysis') {
                    steps {
                        echo "Running SonarQube quality gate analysis..."
                        // Simulated step
                    }
                }
            }
        }

        // Conditional stage execution using 'when'
        stage('Integration Testing') {
            when {
                allOf {
                    environment name: 'DEPLOY_TARGET', value: 'staging'
                    expression { return params.RUN_INTEGRATION_TESTS == true }
                }
            }
            steps {
                echo "All conditions met. Executing rigorous integration test framework..."
            }
        }

        // Script block execution mapping procedural Groovy
        stage('Complex Deployment Logic') {
            steps {
                script {
                    def deploymentClusters = ['cluster-us-east', 'cluster-us-west', 'cluster-eu-central']
                    
                    try {
                        for (cluster in deploymentClusters) {
                            echo "Deploying artifact to target cluster: ${cluster}"
                            // sh "deploy_script.sh --target=${cluster}"
                        }
                    } catch (Exception err) {
                        currentBuild.result = 'UNSTABLE'
                        echo "Deployment matrix partially failed: ${err.getMessage()}"
                    }
                }
            }
        }

        // Input directive to pause execution for manual human intervention
        stage('Promote to Production') {
            input {
                message "Do you want to release this build to Production?"
                ok "Yes, Release it!"
                submitter "release-managers-group"
                parameters {
                    string(name: 'APPROVER_NOTES', defaultValue: '', description: 'Reason for approval')
                }
            }
            steps {
                echo "Release approved by authority. Notes: ${投递参数 -> params.APPROVER_NOTES}"
            }
        }
    }

    // 8. Post Actions - Executes conditionally depending on the final status of the pipeline run
    post {
        always {
            echo "Pipeline complete. Cleaning workspace resources..."
            cleanWs() // Deletes the workspace folder to save disk space
        }
        success {
            echo "Build finished successfully! Sending success alerts..."
            // emailext body: 'Build succeeded', subject: 'Success', to: 'team@company.com'
        }
        failure {
            echo "Pipeline crashed. Notifying on-call engineers..."
            // slackSend channel: '#alerts', message: "Build Failed: ${env.BUILD_URL}"
        }
        unstable {
            echo "Pipeline finished but with testing failures or compiler warnings."
        }
        changed {  
            echo "The status of the build changed from the previous run (e.g., fixed or broken)."
        }
    }
} 