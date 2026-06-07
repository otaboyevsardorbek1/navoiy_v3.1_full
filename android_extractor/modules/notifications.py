"""
Android Studio Loyiha Tahlilchisi - Xabar yuborish moduli
"""
import os
import json
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime


class NotificationManager:
    """Xabar yuborish tizimi"""

    def __init__(self, config_manager, logger):
        self.config = config_manager
        self.logger = logger

    def send_email(self, subject, body, attachments=None):
        """Email yuborish"""
        email_config = self.config.get('notifications.email', {})

        if not email_config.get('enabled', False):
            self.logger.info("Email xabarlar o'chirilgan")
            return False

        try:
            smtp_host = email_config.get('smtp_host', '')
            smtp_port = email_config.get('smtp_port', 587)
            username = email_config.get('username', '')
            password = email_config.get('password', '')
            from_addr = email_config.get('from_addr', username)
            to_addrs = email_config.get('to_addrs', [])

            if not all([smtp_host, username, password, to_addrs]):
                self.logger.warning("Email sozlamalari to'liq emas")
                return False

            msg = MIMEMultipart()
            msg['From'] = from_addr
            msg['To'] = ', '.join(to_addrs)
            msg['Subject'] = subject

            msg.attach(MIMEText(body, 'plain', 'utf-8'))

            # Attachments
            if attachments:
                for attachment in attachments:
                    if os.path.exists(attachment):
                        from email.mime.base import MIMEBase
                        from email import encoders

                        with open(attachment, 'rb') as f:
                            part = MIMEBase('application', 'octet-stream')
                            part.set_payload(f.read())

                        encoders.encode_base64(part)
                        part.add_header(
                            'Content-Disposition',
                            f'attachment; filename= {os.path.basename(attachment)}'
                        )
                        msg.attach(part)

            server = smtplib.SMTP(smtp_host, smtp_port)
            server.starttls()
            server.login(username, password)
            server.send_message(msg)
            server.quit()

            self.logger.info(f"Email yuborildi: {subject}")
            return True

        except Exception as e:
            self.logger.error(f"Email yuborishda xato: {e}")
            return False

    def send_telegram(self, message):
        """Telegram xabar yuborish"""
        telegram_config = self.config.get('notifications.telegram', {})

        if not telegram_config.get('enabled', False):
            self.logger.info("Telegram xabarlar o'chirilgan")
            return False

        try:
            import requests

            bot_token = telegram_config.get('bot_token', '')
            chat_id = telegram_config.get('chat_id', '')

            if not all([bot_token, chat_id]):
                self.logger.warning("Telegram sozlamalari to'liq emas")
                return False

            url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            data = {
                'chat_id': chat_id,
                'text': message,
                'parse_mode': 'HTML'
            }

            response = requests.post(url, data=data, timeout=30)

            if response.status_code == 200:
                self.logger.info("Telegram xabar yuborildi")
                return True
            else:
                self.logger.warning(f"Telegram xato: {response.status_code}")
                return False

        except ImportError:
            self.logger.warning("requests kutubxonasi o'rnatilmagan")
            return False
        except Exception as e:
            self.logger.error(f"Telegram xabar yuborishda xato: {e}")
            return False

    def notify_analysis_complete(self, results, attachments=None):
        """Tahlil tugaganda xabar yuborish"""
        subject = "Android Studio Loyiha Tahlili - Yakunlandi"

        body = f"""
Android Studio Loyiha Tahlili Yakunlandi!

Sana: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Natijalar:
- Jami fayllar: {results.get('total_files', 0)}
- Jami qatorlar: {results.get('total_lines', 0):,}
- Modullar: {results.get('modules', 0)}

Hisobotlar quyidagi formatlarda yaratildi:
"""

        for path in results.get('generated_files', []):
            body += f"- {path}\n"

        # Email
        self.send_email(subject, body, attachments)

        # Telegram
        telegram_msg = f"<b>📱 Android Tahlil Yakunlandi!</b>\n\n"
        telegram_msg += f"📁 Fayllar: {results.get('total_files', 0)}\n"
        telegram_msg += f"📝 Qatorlar: {results.get('total_lines', 0):,}\n"
        telegram_msg += f"🔧 Modullar: {results.get('modules', 0)}\n"

        self.send_telegram(telegram_msg)
