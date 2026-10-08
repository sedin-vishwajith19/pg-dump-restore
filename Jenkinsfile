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
            description: '[RESTORE] Or specify an existing dump filename/path (e.g. dumps/my_backup.dump)'
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

                        // Check 1: File Parameter object or workspace file
                        if (params.DUMP_FILE_UPLOAD && fileExists(params.DUMP_FILE_UPLOAD.toString())) {
                            fileToRestore = params.DUMP_FILE_UPLOAD.toString()
                            echo "Found uploaded file at: ${fileToRestore}"
                        } else if (fileExists('DUMP_FILE_UPLOAD')) {
                            fileToRestore = 'DUMP_FILE_UPLOAD'
                            echo "Found uploaded file 'DUMP_FILE_UPLOAD' in workspace."
                        } else if (params.RESTORE_DUMP_FILE && params.RESTORE_DUMP_FILE.trim() != '') {
                            fileToRestore = params.RESTORE_DUMP_FILE.trim()
                            echo "Using specified RESTORE_DUMP_FILE: ${fileToRestore}"
                        } else {
                            // Check 4: Look for any .dump file in workspace or dumps folder
                            def foundFiles = sh(
                                script: 'find . -maxdepth 2 -name "*.dump" ! -name "pre_restore_safety_*.dump" | head -n 1',
                                returnStdout: true
                            ).trim()

                            if (foundFiles != '') {
                                fileToRestore = foundFiles
                                echo "Auto-detected dump file in workspace: ${fileToRestore}"
                            } else {
                                error("No dump file found! Please upload a file (DUMP_FILE_UPLOAD) or specify RESTORE_DUMP_FILE parameter.")
                            }
                        }

                        echo "Executing restore with file: ${fileToRestore}"
                        sh "chmod +x restore.sh && ./restore.sh '${fileToRestore}'"
                    }
                }
            }
        }
    }
}