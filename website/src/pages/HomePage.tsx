import { Link } from 'react-router-dom'
import SEO from '../components/SEO'
import './HomePage.css'

export default function HomePage() {
    const currentYear = new Date().getFullYear()

    return (
        <>
            <SEO />

            <div className="container">
                <div className="content">
                    <div className="app-icon">
                        <img src="/wutzup-icon.jpg" alt="Wutzup International" className="icon-image" />
                    </div>
                    <h1 className="title">Wutzup International</h1>
                    <h2 className="subtitle">
                        Language Learning & Global Communication
                    </h2>
                    <p className="description">
                        Connect with AI language tutors, practice conversations, and communicate globally.
                        Perfect for language learners and international travelers.
                    </p>

                    <div className="download-section">
                        <a
                            href="https://apps.apple.com/us/app/wutzup/id6754276286"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="app-store-link"
                        >
                            <img
                                src="https://raw.githubusercontent.com/landscapesupply/images/refs/heads/main/app-store/download-on-apple-apple-store-landscape-supply-marketplace-buy-delivery-mulch-rock-sod-gravel-stone-near-me.png"
                                alt="Download on App Store"
                                className="app-store-badge"
                            />
                        </a>
                    </div>

                    <div className="features">
                        <div className="feature">
                            <div className="feature-icon">🎓</div>
                            <h3>AI Language Tutors</h3>
                            <p>Practice with native-speaking AI tutors in 20+ languages including Spanish, French, German, Japanese, and more.</p>
                        </div>

                        <div className="feature">
                            <div className="feature-icon">✈️</div>
                            <h3>Travel-Ready Messaging</h3>
                            <p>Stay connected with friends and family while traveling internationally with reliable offline messaging.</p>
                        </div>

                        <div className="feature">
                            <div className="feature-icon">🔄</div>
                            <h3>Real-Time Translation</h3>
                            <p>Get instant translations and context explanations to help you learn and communicate effectively.</p>
                        </div>

                        <div className="feature">
                            <div className="feature-icon">👥</div>
                            <h3>Group Learning</h3>
                            <p>Create study groups with tutors and practice conversations with multiple participants.</p>
                        </div>

                        <div className="feature">
                            <div className="feature-icon">🎬</div>
                            <h3>Visual Learning</h3>
                            <p>Generate custom GIFs and visual content to enhance your language learning experience and express yourself creatively.</p>
                        </div>

                        <div className="feature">
                            <div className="feature-icon">💡</div>
                            <h3>Smart Context</h3>
                            <p>Get AI-powered explanations of conversations, cultural insights, and learning tips to deepen your understanding.</p>
                        </div>
                    </div>

                    <div className="footer">
                        <Link to="/support" className="link">
                            Support
                        </Link>
                        <span className="footer-separator"> • </span>
                        <Link to="/privacy-policy" className="link">
                            Privacy Policy
                        </Link>
                    </div>

                    <div className="footer-download">
                        <a
                            href="https://apps.apple.com/us/app/wutzup/id6754276286"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="app-store-link-small"
                        >
                            <img
                                src="https://raw.githubusercontent.com/landscapesupply/images/refs/heads/main/app-store/download-on-apple-apple-store-landscape-supply-marketplace-buy-delivery-mulch-rock-sod-gravel-stone-near-me.png"
                                alt="Download on App Store"
                                className="app-store-badge-small"
                            />
                        </a>
                    </div>

                    <div className="copyright">
                        <p>© {currentYear} <a href="https://archlife.org" target="_blank" rel="noopener noreferrer" className="company-link">Archlife Industries Software</a></p>
                    </div>
                </div>
            </div>
        </>
    )
}

