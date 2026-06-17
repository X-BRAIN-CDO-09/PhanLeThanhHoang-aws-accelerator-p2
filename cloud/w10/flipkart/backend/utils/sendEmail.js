// const nodeMailer = require('nodemailer');
const sgMail = require('@sendgrid/mail')

const sendgridApiKey = process.env.SENDGRID_API_KEY;
const sendgridFrom = process.env.SENDGRID_MAIL;
const hasValidSendgridConfig =
    typeof sendgridApiKey === 'string' && sendgridApiKey.startsWith('SG.') &&
    typeof sendgridFrom === 'string' && sendgridFrom.length > 0;

if (hasValidSendgridConfig) {
    sgMail.setApiKey(sendgridApiKey);
}

const sendEmail = async (options) => {

    // const transporter = nodeMailer.createTransport({
    //     host: process.env.SMTP_HOST,
    //     port: process.env.SMTP_PORT,
    //     service: process.env.SMTP_SERVICE,
    //     auth: {
    //         user: process.env.SMTP_MAIL,
    //         pass: process.env.SMTP_PASSWORD,
    //     },
    // });

    // const mailOptions = {
    //     from: process.env.SMTP_MAIL,
    //     to: options.email,
    //     subject: options.subject,
    //     html: options.message,
    // };

    // await transporter.sendMail(mailOptions);

    if (!hasValidSendgridConfig) {
        console.warn('SendGrid is not configured with a valid key. Skipping email send.');
        return;
    }

    const msg = {
        to: options.email,
        from: sendgridFrom,
        templateId: options.templateId,
        dynamic_template_data: options.data,
    }
    sgMail.send(msg).then(() => {
        console.log('Email Sent')
    }).catch((error) => {
        console.error(error)
    });
};

module.exports = sendEmail;