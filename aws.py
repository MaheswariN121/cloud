import pandas as pd
import requests
import io
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

# URL of the Parquet file on Google Drive
parquet_url = 'https://drive.google.com/uc?id=1aD8KRatbDbdCv3T6Zuq7NUi8znJtiLGu'

# Download the Parquet file
response = requests.get(parquet_url)
parquet_data = io.BytesIO(response.content)

# Read the Parquet data into a DataFrame
df = pd.read_parquet(parquet_data)

# Convert DataFrame to CSV
csv_data = df.to_csv(index=False)

# Email configuration
sender_email = "your_sender_email@gmail.com"
sender_password = "your_sender_email_password"
receiver_email = "your_receiver_email@gmail.com"

# Create a multipart message and set headers
msg = MIMEMultipart()
msg['From'] = sender_email
msg['To'] = receiver_email
msg['Subject'] = "CSV File Attached"

# Add body to email
body = "Please find the attached CSV file."
msg.attach(MIMEText(body, 'plain'))

# Add CSV attachment
attachment = MIMEBase('application', 'octet-stream')
attachment.set_payload(csv_data.encode('utf-8'))
encoders.encode_base64(attachment)
attachment.add_header('Content-Disposition', 'attachment', filename="userdata.csv")
msg.attach(attachment)

# Connect to SMTP server and send email
with smtplib.SMTP('smtp.gmail.com', 587) as server:
    server.starttls()
    server.login(sender_email, sender_password)
    text = msg.as_string()
    server.sendmail(sender_email, receiver_email, text)

print("Email sent successfully!")
