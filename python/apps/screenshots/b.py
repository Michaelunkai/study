import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def send_email(recipient, subject, body):
    # Set up the SMTP server
    server = smtplib.SMTP("smtp.gmail.com", 587)
    server.starttls()

    # Login to your email account
    server.login("michaelovsky5@gmail.com", "Aa111111!")

    # Create a new email message
    msg = MIMEMultipart()
    msg['From'] = 'michaelovsky5@gmail.com'
    msg['To'] = recipient
    msg['Subject'] = subject
    msg.attach(MIMEText(body))

    # Send the email and close the connection
    server.sendmail(msg['From'], msg['To'], msg.as_string())
    server.quit()

# Loop to send 10 emails
for i in range(1, 11):
    subject = f"Hello {i}"
    body = "hello"
    recipient = "michaelovsky5@gmail.com"
    send_email(recipient, subject, body)