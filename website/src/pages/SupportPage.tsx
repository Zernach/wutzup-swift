import { Link } from 'react-router-dom'
import SEO from '../components/SEO'
import './SupportPage.css'

export default function SupportPage() {
    const currentYear = new Date().getFullYear()

    return (
        <>
            <SEO
                title="Support - Wutzup AI"
                description="Need help with Wutzup? Contact our support team via email and we'll be happy to assist you."
                url="https://wutzup.archlife.org/support"
            />

            <div className="support-container">
                <div className="support-content">
                    <Link to="/" className="back-button">
                        ← Back to Home
                    </Link>

                    <div className="support-emoji">💬</div>
                    <h1 className="support-title">We're Here to Help</h1>
                    <p className="support-subtitle">
                        Have questions or need assistance? We'd love to hear from you!
                    </p>

                    <div className="email-section">
                        <h2 className="section-heading">Get in Touch</h2>
                        <p className="support-text">
                            Our support team is ready to help you with any questions, feedback, or issues you might have.
                            Send us an email and we'll get back to you as soon as possible.
                        </p>

                        <a
                            href="mailto:wutzup@archlife.org"
                            className="email-button"
                        >
                            <span className="email-icon">✉️</span>
                            <span className="email-address">wutzup@archlife.org</span>
                        </a>
                    </div>

                    <div className="info-section">
                        <h3 className="info-title">What can we help you with?</h3>
                        <ul className="help-list">
                            <li>Account questions and setup</li>
                            <li>Technical issues or bugs</li>
                            <li>Feature requests and suggestions</li>
                            <li>Privacy and security concerns</li>
                            <li>General inquiries about Wutzup</li>
                        </ul>
                    </div>

                    <div className="footer-links">
                        <Link to="/" className="footer-link">Home</Link>
                        <span className="separator">•</span>
                        <Link to="/privacy-policy" className="footer-link">Privacy Policy</Link>
                    </div>

                    <div className="copyright">
                        <p>© {currentYear} <a href="https://archlife.org" target="_blank" rel="noopener noreferrer" className="company-link">Archlife Industries Software</a></p>
                    </div>
                </div>
            </div>
        </>
    )
}

