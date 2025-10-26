import { useEffect } from 'react'

interface SEOProps {
    title?: string
    description?: string
    url?: string
    image?: string
}

export default function SEO({
    title = 'Wutzup International - Language Learning & Global Communication',
    description = 'Connect with AI language tutors, practice conversations, and communicate globally. Perfect for language learners and international travelers.',
    url = 'https://wutzup.archlife.org/',
    image = '/wutzup-icon.jpg'
}: SEOProps) {
    useEffect(() => {
        // Update document title
        document.title = title

        // Update meta tags
        const metaTags = {
            'description': description,
            'og:title': title,
            'og:description': description,
            'og:url': url,
            'og:image': image,
            'twitter:title': title,
            'twitter:description': description,
            'twitter:url': url,
            'twitter:image': image,
        }

        Object.entries(metaTags).forEach(([name, content]) => {
            const isProperty = name.startsWith('og:') || name.startsWith('twitter:')
            const attribute = isProperty ? 'property' : 'name'

            let element = document.querySelector(`meta[${attribute}="${name}"]`)

            if (element) {
                element.setAttribute('content', content)
            } else {
                element = document.createElement('meta')
                element.setAttribute(attribute, name)
                element.setAttribute('content', content)
                document.head.appendChild(element)
            }
        })
    }, [title, description, url, image])

    return null
}

