pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['DUMP', 'RUN_SCRIPT'],
            description: 'Choose DUMP to backup database OR RUN_SCRIPT to execute SQL script'
        )

        text(
            name: 'SQL_SCRIPT',
            defaultValue: '',
            description: 'Paste SQL script / commands here (Required when ACTION is RUN_SCRIPT)'
        )
    }

    environment {
        SSH_CREDENTIALS_ID = 'db-server-ssh-key'
        SERVER_HOST        = '98.70.45.119'
        SERVER_USER        = 'deployer'
        CONTAINER_NAME     = 'landmark-db'
        DB_NAME            = 'postgres_local'
        DB_USER            = 'postgres_local'
        REMOTE_DUMPS_PATH  = '/var/www/dkapp/DS_audit/dumps'
        LOCAL_DUMP_DIR     = "${WORKSPACE}/dumps"
    }

    stages {
        stage('Dump Database') {
            when {
                expression { return params.ACTION == 'DUMP' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY_PATH')]) {
                    sh "chmod +x dump.sh && ./dump.sh"
                }
                archiveArtifacts artifacts: 'dumps/*.dump', allowEmptyArchive: false
            }
        }

        stage('Execute SQL Script in Container') {
            when {
                expression { return params.ACTION == 'RUN_SCRIPT' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY_PATH')]) {
                    script {
                        if (!params.SQL_SCRIPT || params.SQL_SCRIPT.trim() == '') {
                            error("No SQL script provided! Please paste your SQL queries in the SQL_SCRIPT area.")
                        }

                        echo "Writing pasted script to script.sql..."
                        writeFile file: 'script.sql', text: params.SQL_SCRIPT.trim()

                        echo "Executing script inside container '${env.CONTAINER_NAME}'..."
                        sh "chmod +x run-script.sh && ./run-script.sh script.sql"
                    }
                }
            }
        }
    }
}