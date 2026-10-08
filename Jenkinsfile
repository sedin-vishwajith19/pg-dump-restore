pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['DUMP', 'RESTORE'],
            description: 'Choose DUMP to backup database or RESTORE to restore database'
        )

        file(
            name: 'DUMP_FILE_UPLOAD',
            description: '[RESTORE] Upload a .dump file from your local computer'
        )

        string(
            name: 'RESTORE_DUMP_FILE',
            defaultValue: '',
            description: '[RESTORE] Or specify an existing dump filename/path'
        )

        string(
            name: 'SSH_CREDENTIALS_ID',
            defaultValue: 'db-server-ssh-key',
            description: 'Jenkins SSH credential ID'
        )

        string(
            name: 'SERVER_HOST',
            defaultValue: '98.70.45.119',
            description: 'Target database server IP'
        )

        string(
            name: 'SERVER_USER',
            defaultValue: 'deployer',
            description: 'SSH username'
        )

        string(
            name: 'CONTAINER_NAME',
            defaultValue: 'landmark-db',
            description: 'PostgreSQL Docker container name'
        )

        string(
            name: 'DB_NAME',
            defaultValue: 'postgres_local',
            description: 'Database name'
        )

        string(
            name: 'DB_USER',
            defaultValue: 'postgres_local',
            description: 'Database user'
        )

        string(
            name: 'REMOTE_DUMPS_PATH',
            defaultValue: '/var/www/dkapp/DS_audit/dumps',
            description: 'Remote dumps path'
        )
    }

    environment {
        LOCAL_DUMP_DIR = "${WORKSPACE}/dumps"
    }

    stages {
        stage('Dump Database') {
            when {
                expression { return params.ACTION == 'DUMP' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY_PATH')]) {
                    sh "chmod +x dump.sh && ./dump.sh"
                }
                archiveArtifacts artifacts: 'dumps/*.dump', allowEmptyArchive: false
            }
        }

        stage('Restore Database') {
            when {
                expression { return params.ACTION == 'RESTORE' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY_PATH')]) {
                    script {
                        def fileToRestore = ""

                        if (fileExists('DUMP_FILE_UPLOAD')) {
                            echo "Found uploaded file."
                            sh "mkdir -p dumps && mv DUMP_FILE_UPLOAD dumps/uploaded.dump"
                            fileToRestore = "dumps/uploaded.dump"
                        } else if (params.RESTORE_DUMP_FILE && params.RESTORE_DUMP_FILE.trim() != '') {
                            fileToRestore = params.RESTORE_DUMP_FILE.trim()
                        } else {
                            error("Please upload a file or specify RESTORE_DUMP_FILE!")
                        }

                        sh "chmod +x restore.sh && ./restore.sh '${fileToRestore}'"
                    }
                }
            }
        }
    }
}