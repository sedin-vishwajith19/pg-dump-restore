pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['DUMP', 'RUN_SCRIPT'],
            description: 'Choose DUMP to backup database OR RUN_SCRIPT to execute a SQL script in the container'
        )

        file(
            name: 'SCRIPT_FILE_UPLOAD',
            description: '[RUN_SCRIPT] Upload a .sql script file from your computer'
        )

        text(
            name: 'SQL_QUERY_OR_SCRIPT',
            defaultValue: '',
            description: '[RUN_SCRIPT] Or paste raw SQL queries/commands directly here (Leave empty if uploading a file)'
        )

        string(
            name: 'SCRIPT_FILE_PATH',
            defaultValue: '',
            description: '[RUN_SCRIPT] Or specify a script filename/path in workspace'
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

        stage('Execute Script in Database Container') {
            when {
                expression { return params.ACTION == 'RUN_SCRIPT' || params.ACTION == 'RESTORE' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY_PATH')]) {
                    script {
                        def scriptToRun = ""

                        // 1. Check if user typed or pasted SQL query/script in text parameter
                        if (params.SQL_QUERY_OR_SCRIPT && params.SQL_QUERY_OR_SCRIPT.trim() != '') {
                            echo "Detected inline SQL text. Writing to custom_query.sql..."
                            writeFile file: 'custom_query.sql', text: params.SQL_QUERY_OR_SCRIPT.trim()
                            scriptToRun = 'custom_query.sql'
                        }
                        // 2. Check if a script file was uploaded
                        else if (params.SCRIPT_FILE_UPLOAD && fileExists(params.SCRIPT_FILE_UPLOAD.toString())) {
                            scriptToRun = params.SCRIPT_FILE_UPLOAD.toString()
                        } else if (fileExists('SCRIPT_FILE_UPLOAD')) {
                            scriptToRun = 'SCRIPT_FILE_UPLOAD'
                        } else if (fileExists('DUMP_FILE_UPLOAD')) {
                            scriptToRun = 'DUMP_FILE_UPLOAD'
                        }
                        // 3. Check if script path was provided
                        else if (params.SCRIPT_FILE_PATH && params.SCRIPT_FILE_PATH.trim() != '') {
                            scriptToRun = params.SCRIPT_FILE_PATH.trim()
                        } else if (params.RESTORE_DUMP_FILE && params.RESTORE_DUMP_FILE.trim() != '') {
                            scriptToRun = params.RESTORE_DUMP_FILE.trim()
                        } else {
                            // 4. Auto-detect any .sql file in workspace
                            def foundSql = sh(
                                script: 'find . -maxdepth 2 -name "*.sql" | head -n 1',
                                returnStdout: true
                            ).trim()

                            if (foundSql != '') {
                                scriptToRun = foundSql
                            } else {
                                error("No script provided! Please upload a .sql file, paste SQL text in SQL_QUERY_OR_SCRIPT, or specify SCRIPT_FILE_PATH.")
                            }
                        }

                        echo "Executing script '${scriptToRun}' on container '${params.CONTAINER_NAME}'..."
                        sh "chmod +x run-script.sh && ./run-script.sh '${scriptToRun}'"
                    }
                }
            }
        }
    }
}