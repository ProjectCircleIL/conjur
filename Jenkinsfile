#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }
  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    skipDefaultCheckout()  // see 'Checkout SCM' below, once perms are fixed this is no longer needed
    timeout(time: 1, unit: 'HOURS')
  }
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
        sh 'git fetch' // to pull the tags
      }
    }
    stage('Run Tests') {
      parallel {
        stage('GCP Authenticator - setup test env') {
          steps {
            script {
              echo 'Allocate Google compute engine'
              node('executor-v2-gcp-small') {
                env.GCP_PROJECT = sh(script: 'curl \
                -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" \
                -H "Metadata-Flavor: Google"', , returnStdout: true).trim()
                echo "inside executor-v2-gcp-small, GCP_PROJECT: ${GCP_PROJECT}"
              }

              echo "Google compute engine allocated, GCP_PROJECT: ${GCP_PROJECT}"
              env.GCP_FETCH_TOKEN_FUNCTION = "fetch_token_${BUILD_NUMBER}"
              env.GCP_FUNC_URL="https://us-central1-${GCP_PROJECT}.cloudfunctions.net/${GCP_FETCH_TOKEN_FUNCTION}"
              echo "GCP_FUNC_URL: ${GCP_FUNC_URL}"
            }

            echo 'Deploy Google cloud function'
            dir('ci/authn-gcp') {
              sh '''
              chmod +x run_gcloud.sh
              summon ./run_gcloud.sh deploy_function.sh
              '''
            }
            echo 'Google cloud function deployed'
            echo 'set GCP_TOKENS_FETCHED to true'
          }
          environment {
            GCP_TOKENS_FETCHED = "true"
          }
        }        
      }
    }
  }
}