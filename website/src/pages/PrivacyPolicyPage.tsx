import { Link } from 'react-router-dom'
import SEO from '../components/SEO'
import './PrivacyPolicyPage.css'

export default function PrivacyPolicyPage() {
    const currentYear = new Date().getFullYear()

    return (
        <>
            <SEO
                title="Privacy Policy - Wutzup AI"
                description="Learn how Wutzup AI protects your privacy and handles your data. We respect your privacy and never sell your data to third parties."
                url="https://wutzup.archlife.org/privacy-policy"
            />

            <div className="privacy-container">
                <div className="privacy-content">
                    <Link to="/" className="back-button">
                        ← Back to Home
                    </Link>

                    <h1 className="privacy-title">Privacy Policy</h1>
                    <p className="last-updated">Last updated: October 21, 2025</p>

                    <section className="section">
                        <h2 className="section-title">Your Privacy Matters</h2>
                        <p className="paragraph">
                            At Wutzup, we deeply respect your privacy. We believe that your conversations
                            and personal data should remain yours. This privacy policy outlines our commitment
                            to protecting your information.
                        </p>
                    </section>

                    <section className="section">
                        <h2 className="section-title">Data We Collect</h2>
                        <p className="paragraph">
                            We collect only the essential information needed to provide our messaging service:
                        </p>
                        <ul className="bullet-list">
                            <li>Account information (email, username)</li>
                            <li>Messages you send and receive</li>
                            <li>Basic usage data to improve our service</li>
                        </ul>
                    </section>

                    <section className="section">
                        <h2 className="section-title">How We Use Your Data</h2>
                        <p className="paragraph">
                            Your data is used solely to:
                        </p>
                        <ul className="bullet-list">
                            <li>Deliver messages between you and your contacts</li>
                            <li>Maintain and improve our service</li>
                            <li>Ensure the security of our platform</li>
                        </ul>
                        <p className="paragraph emphasis">
                            We never sell your data to third parties. Period.
                        </p>
                    </section>

                    <section className="section">
                        <h2 className="section-title">Data Security</h2>
                        <p className="paragraph">
                            We implement industry-standard security measures to protect your information.
                            Your messages are transmitted securely, and we continuously monitor our systems
                            for potential vulnerabilities.
                        </p>
                    </section>

                    <section className="section">
                        <h2 className="section-title">Your Rights</h2>
                        <p className="paragraph">
                            You have the right to:
                        </p>
                        <ul className="bullet-list">
                            <li>Access your personal data</li>
                            <li>Request deletion of your data</li>
                            <li>Export your data</li>
                            <li>Opt out of non-essential data collection</li>
                        </ul>
                    </section>

                    <section className="section">
                        <h2 className="section-title">Contact Us</h2>
                        <p className="paragraph">
                            If you have any questions about this privacy policy or how we handle your data,
                            please don't hesitate to reach out to us.
                        </p>
                    </section>

                    <div className="privacy-footer">
                        <Link to="/" className="link">
                            Back to Home
                        </Link>
                    </div>

                    <div className="copyright">
                        <p>© {currentYear} <a href="https://archlife.org" target="_blank" rel="noopener noreferrer" className="company-link">Archlife Industries Software</a></p>
                    </div>
                </div>
            </div>
        </>
    )
}

