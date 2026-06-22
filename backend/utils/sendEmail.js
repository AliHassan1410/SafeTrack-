import nodemailer from "nodemailer";

const sendEmail = async ({ to, subject, html }) => {
  try {
    let transporter;

    if (process.env.SMTP_EMAIL && process.env.SMTP_PASSWORD) {
      // Use real email provider if configured
      transporter = nodemailer.createTransport({
        service: "Gmail",
        auth: {
          user: process.env.SMTP_EMAIL,
          pass: process.env.SMTP_PASSWORD,
        },
      });
    } else {
      // Fallback to Ethereal Email for testing during development
      console.log("No SMTP credentials found. Creating Ethereal test account...");
      const testAccount = await nodemailer.createTestAccount();
      transporter = nodemailer.createTransport({
        host: "smtp.ethereal.email",
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });
    }

    const mailOptions = {
      from: `SafeTrack <${process.env.SMTP_EMAIL || "test@safetrack.local"}>`,
      to,
      subject,
      html,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log("Email sent successfully!");
    
    if (!process.env.SMTP_EMAIL) {
      console.log("-----------------------------------------");
      console.log("💡 TEST EMAIL URL: ", nodemailer.getTestMessageUrl(info));
      console.log("-----------------------------------------");
    }
    
    return true;
  } catch (error) {
    console.error("Error sending email:", error);
    return false;
  }
};

export default sendEmail;
