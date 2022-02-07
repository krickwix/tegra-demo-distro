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
                withEnv(['LANG="C"']) {
                    sh(". setup-env --machine jetson-nano-devkit-emmc --distro tegrademo && \
		    cat >> conf/local.conf << EOF
		    SOURCE_MIRROR_URL = "http://10.60.16.240/x86"
		    INHERIT += "own-mirrors"
		    EOF
                    MACHINE=jetson-nano-devkit-emmc bitbake demo-image-full && \
                    MACHINE=jetson-nano-devkit bitbake demo-image-full && \
                    MACHINE=jetson-xavier-nx-devkit bitbake demo-image-full && \
                    MACHINE=jetson-xavier-nx-devkit-tx2-nx bitbake demo-image-full")
                }
            }
        }
	stage("artefacts") {
            steps {
                archiveArtifacts artifacts: 'build/tmp/deploy/images/**/*.tegraflash.tar.gz',
                   allowEmptyArchive: true,
                   fingerprint: true,
                   onlyIfSuccessful: true
		minio bucket: 'gbear-yocto-images-jetson',
                   credentialsId: 'minio_gbear-user',
                   targetFolder: 'jenkins-build/',
                   host: 'http://10.60.16.240:9199',
                   includes: 'build/tmp-glibc/deploy/images/**/*.tegraflash.tar.gz'
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
