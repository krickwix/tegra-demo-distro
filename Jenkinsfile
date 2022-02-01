pipeline {
    agent { label 'yocto'}
    stages {
        stage ('dependencies') {
            steps {
                withEnv(['DEBIAN_FRONTEND=noninteractive']) {
                    sh('sudo apt -y update && sudo apt -y upgrade && sudo apt -y install openjdk-11-jdk build-essential gcc-8 g++-8 git bmap-tools chrpath diffstat zstd')
                }
            }
        }
        stage('scm') {
            steps {
                withEnv(['LANG="C"']) {
                    sh("git submodule update --init --recursive --jobs 32")
                }
            }
        }
        stage("build") {
            steps {
                withEnv(['LANG="C"','all_proxy="http://proxy.esl.cisco.com:80"']) {
                    sh(". setup-env --machine jetson-nano-devkit-emmc --distro tegrademo && \
                    MACHINE=jetson-nano-devkit-emmc bitbake demo-image-full && \
                    MACHINE=jetson-nano-devkit bitbake demo-image-full && \
                    MACHINE=jetson-xavier-nx-devkit bitbake demo-image-full && \
                    MACHINE=jetson-xavier-nx-devkit-tx2-nx bitbake demo-image-full")
                }
            }
        }
    }
    post {
        // Clean after build
        always {
            cleanWs()
        }
    }
}
