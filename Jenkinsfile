/**
 * Sample app for `devops-ci-lib` integration testing after refactoring
 * */
@Library('devops-ci-lib@paragate')
import org.devops.Constants
import org.devops.Utills


cluster = "globaldevtools"
label = 'python'
pod_template = cloudInfo.template(cluster, [label,])
pod_cloud = cloudInfo.cloud(cluster)

pipeline {
    agent {
        kubernetes {
            cloud pod_cloud
            label label
            yaml pod_template
        }
    }
    environment {
        ORG = 'test-arttifacts' // artifact repo
        APP_NAME = 'test-cilib'
        version = VersionNumber(versionNumberString: '${BUILD_YEAR}.${BUILD_MONTH}-rc-${BUILDS_THIS_MONTH}')
    }

    stages {
        // this stage is not refactored at this moment and is not used in production
        stage('CI Build and push snapshot') {
            when {
                branch 'PR-*'
            }
            environment {
                version = VersionNumber(versionNumberString: '${BUILD_YEAR}.${BUILD_MONTH}.SNAPSHOT')
            }
            steps {
                echo "CI Build and push snapshot"
                //preview(ORG, APP_NAME, version)
            }
        }

        stage('Create Release') {
            when {
                branch 'master'
            }
            steps {
                script {
                    echo "Build Release ${ORG}/${APP_NAME}/${version}"
                    release.setVersion(version)
                    release.setTag(version)
                }
            }
        }

        stage('Build Release') {
            when {
                branch 'release/*'
            }
            steps {
                script {
                    echo "Build Release ${ORG}/${APP_NAME}/${version}"
                    release.build(ORG, APP_NAME, version)
                }
            }
        }

        stage("Promote to Environments") {
            when {
                branch 'release/*'
            }
            steps {
                script {
                    echo "Promote to Environments ${ORG}/${APP_NAME}/${version}"
                    cd.promote(ORG, APP_NAME)
                }
            }
        }
    }
}