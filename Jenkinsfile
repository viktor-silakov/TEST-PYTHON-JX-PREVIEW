@Library('devops-ci-lib@paragate')
import org.devops.Constants
import org.devops.Utills

import groovy.json.JsonSlurperClassic

constants = new Constants()

cluster = "globaldevtools"
label = 'python'
(pod, cloud) = podtemplate(cluster, [label,])
pod_template = cloudInfo.template(cluster, [label,])
pod_cloud = cloudInfo.cloud(cluster)
container_to_run = label

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
        repo = "${env.GIT_URL_1}"
        branch = "${env.CHANGE_BRANCH}"
        repo_finish = "${env.GIT_URL}"
        branch_finish = "${env.GIT_BRANCH}"
        version = VersionNumber(versionNumberString: '${BUILD_YEAR}.${BUILD_MONTH}-rc-${BUILDS_THIS_MONTH}')
    }

    stages {
        stage("git checkout") {
            steps {
                git credentialsId: 'vs-bitbucket', url: 'ssh://git@globaldevtools.bbva.com:7999/~viktor.silakov.contractor/test_ci_lib.git'
            }
        }

        stage('Build Release') {
            steps {
                script {
                    echo "Build Release ${ORG}/${APP_NAME}/${version}"
                    old_version = readFile('VERSION').trim()
                    echo "OLD_VERSION: '${old_version}'"
                    release.setVersion(version)
                    sh "cat VERSION"
                    release.build(ORG, APP_NAME, version)
                    release.setTag(version)
//                tagrelease(version)

                }
//                buildrelease(ORG, APP_NAME, version)
//                tagrelease(version)
            }
        }

        stage("TEST: 'Build Release' stage") {
            stages {
                stage("TEST: check setversion method") {
                    steps {
                        script {
                            new_version = readFile('VERSION').trim()
                            echo "new version is: ${new_version}"

                            echo "Check if new version: '${new_version}' is not empty"
                            assert !new_version.empty

                            echo "Check if new version is properly formad"
                            echo "${(new_version.split('-'))}"
                            assert new_version != old_version
                            echo "${(new_version.split('-'))[0]}"
                            echo "${(new Date()[Calendar.YEAR])}.${(new Date()[Calendar.MONTH])}"
                            assert (new_version.split('-'))[0] == "${(new Date()[Calendar.YEAR])}.${(new Date()[Calendar.MONTH] + 1)}"
                            assert (new_version.split('-'))[1] == 'rc'
                            assert !(new_version.split('-'))[2].isEmpty()

                            echo "Check if tags contains new version"
                            withCredentials([
                                    sshUserPrivateKey(credentialsId: Constants.CREDENTIALS_BITBUCKET, keyFileVariable: 'gsp_bitbucket_keyfile')
                            ]) {
                                sh '''
                               export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i ${gsp_bitbucket_keyfile}"
                               git pull
                           '''
                            }
                            tags = sh(returnStdout: true, script: 'git tag').split("\n")
                            echo "TAGS: ${tags}"
                            assert tags.contains(new_version)
                        }
                    }
                }
                stage("TEST: check k8s build") {
                    steps {
                        script {
                            echo "test"
                        }
                    }
                }

                stage("TEST: check AWS build") {
                    steps {
                        script {
                            log.warn "there is no AWS build test!"
                        }
                    }
                }
            }
        }

        stage("debug cd") {
            steps {
                script {
                    cd.promote(ORG, APP_NAME)
                }
            }
        }

        stage('build integration tests') {
            stages {
                stage("check templates") {
                    steps {
                        script {
                            assert pod_template == pod
                            assert pod_cloud == cloud
                        }
                    }
                }

                stage("check artifactory info") {
                    steps {
                        script {
                            log.warn "WARNING: there is no artifactory checks"
                        }
                    }
                }

                stage("check docker image info") {
                    steps {
                        script {
                            // we cannot use constants settings because local registry has other security settings
                            dockerRegistryDomain = 'docker-registry.jx.35.244.82.27.nip.io'
                            imageUrl = "http://${dockerRegistryDomain}/v2/${APP_NAME}/tags/list"
                            content = (new URL(imageUrl)).getText()
                            echo content
                            imageInfo = jsonToObject(content)
                            echo "imageInfo.tags: ${imageInfo.tags}"
                            echo "version: ${version}"
                            assert imageInfo.tags.contains(version)
                        }
                    }
                }


                stage("check application helm chart") {
                    steps {
                        container('jenkins') {
                            script {
                                def ARTIFACTORY_API_URL = "http://35.200.214.167:80/artifactory/api"
                                def storage = "helm-test-upload"
                                def filename = "${APP_NAME}-${version}.tgz"

                                withCredentials([
                                        [$class          : 'UsernamePasswordMultiBinding', credentialsId: 'bot-artifactory',
                                         usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']
                                ]) {
                                    def uri = "${ARTIFACTORY_API_URL}/storage/${storage}/${filename}"
                                    def artInfo = sh returnStdout: true,
                                            script: 'curl -u${USERNAME}:${PASSWORD} -X GET  ' + uri
                                    echo artInfo
                                    artObj = jsonToObject(artInfo)

                                    assert artObj.uri == uri
                                }
                            }
                        }
                    }
                }
                stage("check integration environment requirements") {
                    steps {
                        container('jenkins') {
                            script {
                                def ARTIFACTORY_API_URL = "http://35.200.214.167:80/artifactory/api"
                                def storage = "helm-test-upload"

                                echo "check a local requirements yaml"
                                def content = readFile "environment/env/requirements.yaml"
                                echo content
                                Map yamlObj = Utills.yamlToMap(content)
                                def dep = yamlObj.dependencies.findAll { it.name == APP_NAME }
                                assert dep[0].name == APP_NAME
                                assert dep[0].version == version
                                assert dep[0].repository == Constants.REPOSITORY_HELM_DOWNLOAD

                                echo "check a pushed remote requirements yaml"
                                def new_requirements
                                withCredentials([
                                        sshUserPrivateKey(credentialsId: Constants.CREDENTIALS_BITBUCKET, keyFileVariable: 'gsp_bitbucket_keyfile')
                                ]) {
//                                    def before = sh returnStdout: true, script: 'git show origin/master:environment/env/requirements.yaml'
//                                    export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i ${gsp_bitbucket_keyfile}"

                                    withEnv(["GIT_SSH_COMMAND=ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i ${gsp_bitbucket_keyfile}"]) {
                                        dir("${env.WORKSPACE}/environment") {
                                            sh "pwd"
                                            sh 'git fetch'
                                            new_requirements = sh returnStdout: true, script: 'git show origin/master:env/requirements.yaml'
                                            echo new_requirements
                                        }
                                    }
                                }

                                def new_requirements_map = Utills.yamlToMap(new_requirements)
                                def new_dep = new_requirements_map.dependencies.findAll { it.name == APP_NAME }
                                assert new_dep[0].name == APP_NAME
                                assert new_dep[0].version == version
                                assert new_dep[0].repository == Constants.REPOSITORY_HELM_DOWNLOAD
                            }
                        }
                    }
                }
            }
        }
    }
}

Object jsonToObject(json) {
    (new groovy.json.JsonSlurperClassic()).parseText(json)
}

//String mapToYaml(Map yamlMap) {
//    DumperOptions options = new DumperOptions()
//    options.setDefaultFlowStyle(DumperOptions.FlowStyle.BLOCK)
//    new Yaml(options).dump(yamlMap)
//}
//
//Map yamlToMap(String yaml) {
//    (Map) new Yaml().load(yaml)
//}