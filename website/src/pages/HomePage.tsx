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
                    <div className="emoji">💬</div>
                    <h1 className="title">Wutzup AI</h1>
                    <h2 className="subtitle">
                        Simple, secure messaging for everyone
                    </h2>
                    <p className="description">
                        Connect with friends and family through instant messaging.
                        Fast, reliable, and built with privacy in mind.
                    </p>

                    <div className="footer">
                        <Link to="/privacy-policy" className="link">
                            Privacy Policy
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

