"""
Android Studio Loyiha Tahlilchisi - Integratsiya moduli
"""
import os
import subprocess
import json
from datetime import datetime


class GitIntegration:
    """Git bilan integratsiya"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger

    def is_git_repo(self, path):
        """Git repozitoriy ekanligini tekshirish"""
        git_dir = os.path.join(path, '.git')
        return os.path.isdir(git_dir)

    def auto_commit(self, files_to_commit, message=None):
        """Avtomatik commit qilish"""
        if not self.config.get('integrations.git.auto_commit', False):
            self.logger.info("Git auto-commit o'chirilgan")
            return False

        if not message:
            message = self.config.get(
                'integrations.git.commit_message',
                'Android Extractor: Hisobot yangilandi'
            )

        try:
            # Git status tekshirish
            result = subprocess.run(
                ['git', 'status', '--short'],
                capture_output=True,
                text=True,
                check=True
            )

            if not result.stdout.strip():
                self.logger.info("O'zgarishlar yo'q")
                return True

            # Add
            for file_path in files_to_commit:
                if os.path.exists(file_path):
                    subprocess.run(
                        ['git', 'add', file_path],
                        capture_output=True,
                        check=True
                    )

            # Commit
            subprocess.run(
                ['git', 'commit', '-m', message],
                capture_output=True,
                check=True
            )

            self.logger.info(f"Git commit: {message}")
            return True

        except subprocess.CalledProcessError as e:
            self.logger.error(f"Git xato: {e}")
            return False
        except FileNotFoundError:
            self.logger.warning("Git o'rnatilmagan")
            return False


class JiraIntegration:
    """Jira bilan integratsiya"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger

    def create_ticket(self, summary, description, issue_type='Task'):
        """Jira ticket yaratish"""
        jira_config = self.config.get('integrations.jira', {})

        if not jira_config.get('enabled', False):
            self.logger.info("Jira integratsiya o'chirilgan")
            return None

        try:
            import requests

            url = jira_config.get('url', '')
            username = jira_config.get('username', '')
            api_token = jira_config.get('api_token', '')
            project_key = jira_config.get('project_key', '')

            if not all([url, username, api_token, project_key]):
                self.logger.warning("Jira sozlamalari to'liq emas")
                return None

            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }

            payload = {
                'fields': {
                    'project': {'key': project_key},
                    'summary': summary,
                    'description': description,
                    'issuetype': {'name': issue_type}
                }
            }

            response = requests.post(
                f"{url}/rest/api/2/issue",
                headers=headers,
                json=payload,
                auth=(username, api_token),
                timeout=30
            )

            if response.status_code == 201:
                ticket = response.json()
                self.logger.info(f"Jira ticket yaratildi: {ticket['key']}")
                return ticket
            else:
                self.logger.error(f"Jira xato: {response.status_code} - {response.text}")
                return None

        except ImportError:
            self.logger.warning("requests kutubxonasi o'rnatilmagan")
            return None
        except Exception as e:
            self.logger.error(f"Jira ticket yaratishda xato: {e}")
            return None


class BackupManager:
    """Avtomatik backup boshqaruvi"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger

    def create_backup(self, files_to_backup, backup_dir='backups'):
        """Fayllarni ZIP arxivga saqlash"""
        import zipfile

        os.makedirs(backup_dir, exist_ok=True)

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_name = f"android_extractor_backup_{timestamp}.zip"
        backup_path = os.path.join(backup_dir, backup_name)

        try:
            with zipfile.ZipFile(backup_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for file_path in files_to_backup:
                    if os.path.exists(file_path):
                        arcname = os.path.basename(file_path)
                        zipf.write(file_path, arcname)
                        self.logger.info(f"Backup: {arcname}")

            self.logger.info(f"Backup yaratildi: {backup_path}")
            return backup_path

        except Exception as e:
            self.logger.error(f"Backup yaratishda xato: {e}")
            return None
