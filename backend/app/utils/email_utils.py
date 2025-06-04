import os
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EmailService:
    """邮件服务类
    
    用于发送各种类型的邮件，如验证码、通知等
    """
    
    # 邮件服务器配置（开发环境下可以留空或使用测试服务）
    SMTP_SERVER = os.getenv('SMTP_SERVER', 'smtp.qq.com')
    SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
    EMAIL_USER = os.getenv('EMAIL_USER', '3024582143@qq.com')
    EMAIL_PASSWORD = os.getenv('EMAIL_PASSWORD', 'iwvhpcugqhqidfcg')
    EMAIL_FROM = os.getenv('EMAIL_FROM', '3024582143@qq.com')
    
    # 是否在开发环境中实际发送邮件
    SEND_REAL_EMAILS_IN_DEV = True  # 设置为True则在开发环境中也发送实际邮件
    
    @staticmethod
    def send_email(to_email, subject, html_content):
        """发送HTML格式的邮件
        
        Args:
            to_email: 收件人邮箱
            subject: 邮件主题
            html_content: HTML格式的邮件内容
            
        Returns:
            发送成功返回True，失败返回False
        """
        # 开发环境下记录邮件内容
        if os.getenv('FLASK_ENV', 'development') == 'development':
            logger.info(f"[DEV MODE] Email to {to_email}: {subject}")
            logger.info(f"[DEV MODE] Content: {html_content}")
            
            # 如果不需要在开发环境中发送实际邮件，则返回
            if not EmailService.SEND_REAL_EMAILS_IN_DEV:
                return True
                
        # 构建邮件
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = EmailService.EMAIL_FROM
        message["To"] = to_email
        
        # 创建HTML部分
        html_part = MIMEText(html_content, "html")
        message.attach(html_part)
        
        try:
            # 创建安全连接
            context = ssl.create_default_context()
            
            # 连接到服务器并发送邮件
            with smtplib.SMTP(EmailService.SMTP_SERVER, EmailService.SMTP_PORT) as server:
                server.ehlo()
                server.starttls(context=context)
                server.ehlo()
                server.login(EmailService.EMAIL_USER, EmailService.EMAIL_PASSWORD)
                server.sendmail(EmailService.EMAIL_FROM, to_email, message.as_string())
                
            logger.info(f"Email sent successfully to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {str(e)}")
            return False
    
    @staticmethod
    def send_verification_code(to_email, code, purpose):
        """发送验证码邮件
        
        Args:
            to_email: 收件人邮箱
            code: 验证码
            purpose: 用途，如'reset_password'或'verify_email'
            
        Returns:
            发送成功返回True，失败返回False
        """
        # 根据用途选择不同的邮件主题和内容
        if purpose == 'reset_password':
            subject = "途乐乐 - 密码重置验证码"
            html = f"""
            <html>
            <body>
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #4A90E2;">途乐乐 - 密码重置</h2>
                    <p>您好，</p>
                    <p>我们收到了您的密码重置请求。请使用以下验证码重置您的密码：</p>
                    <div style="background-color: #f2f2f2; padding: 15px; text-align: center; font-size: 24px; letter-spacing: 5px; margin: 20px 0;">
                        <strong>{code}</strong>
                    </div>
                    <p>此验证码将在30分钟内有效。</p>
                    <p>如果您没有请求密码重置，请忽略此邮件。</p>
                    <p>谢谢！<br>途乐乐团队</p>
                </div>
            </body>
            </html>
            """
        elif purpose == 'verify_email':
            subject = "途乐乐 - 邮箱验证码"
            html = f"""
            <html>
            <body>
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #4A90E2;">途乐乐 - 邮箱验证</h2>
                    <p>您好，</p>
                    <p>请使用以下验证码验证您的邮箱：</p>
                    <div style="background-color: #f2f2f2; padding: 15px; text-align: center; font-size: 24px; letter-spacing: 5px; margin: 20px 0;">
                        <strong>{code}</strong>
                    </div>
                    <p>此验证码将在30分钟内有效。</p>
                    <p>如果您没有进行此操作，请忽略此邮件。</p>
                    <p>谢谢！<br>途乐乐团队</p>
                </div>
            </body>
            </html>
            """
        else:
            subject = "途乐乐 - 验证码"
            html = f"""
            <html>
            <body>
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #4A90E2;">途乐乐 - 验证码</h2>
                    <p>您好，</p>
                    <p>您的验证码是：</p>
                    <div style="background-color: #f2f2f2; padding: 15px; text-align: center; font-size: 24px; letter-spacing: 5px; margin: 20px 0;">
                        <strong>{code}</strong>
                    </div>
                    <p>此验证码将在30分钟内有效。</p>
                    <p>如果您没有进行此操作，请忽略此邮件。</p>
                    <p>谢谢！<br>途乐乐团队</p>
                </div>
            </body>
            </html>
            """
        
        return EmailService.send_email(to_email, subject, html) 