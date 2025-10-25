# Wutzup Firebase Cloud Functions

This directory contains the refactored Firebase Cloud Functions for the Wutzup messaging app, organized for better maintainability and containerization.

## 📁 Project Structure

```
functions/
├── main.py                 # Main entry point - imports all handlers
├── config.py              # Configuration management
├── requirements.txt       # Python dependencies
├── Dockerfile            # Container configuration
├── docker-compose.yml    # Local development setup
├── .dockerignore         # Docker ignore patterns
├── README.md             # This file
├── handlers/             # Function handlers by category
│   ├── __init__.py
│   ├── message_handlers.py      # Message creation triggers
│   ├── conversation_handlers.py # Conversation triggers
│   ├── http_handlers.py        # Basic HTTP endpoints
│   ├── ai_handlers.py          # AI-powered endpoints
│   ├── response_handlers.py    # Response generation
│   ├── gif_handlers.py         # GIF generation
│   ├── research_handlers.py   # Web research
│   └── tutor_handlers.py       # Language tutor AI
└── utils/                # Utility modules
    ├── __init__.py
    ├── ai_utils.py            # AI/OpenAI utilities
    ├── web_utils.py           # Web scraping utilities
    ├── notification_utils.py  # Push notification utilities
    └── image_utils.py         # Image processing utilities
```

## 🚀 Features

### Core Functions
- **Message Triggers**: Automatic push notifications on new messages
- **Presence Tracking**: User online/offline status monitoring
- **Conversation Management**: Group and direct message handling

### AI-Powered Features
- **Translation**: Real-time text translation using OpenAI
- **Cultural Context**: AI analysis of message cultural nuances
- **Language Tutor**: Interactive AI language learning
- **Response Suggestions**: AI-generated conversation responses
- **Web Research**: AI-powered web search and summarization

### Media Generation
- **GIF Creation**: DALL-E powered animated GIF generation
- **Image Processing**: Automated image optimization and formatting

## 🛠️ Development Setup

### Local Development with Docker

1. **Build and run with Docker Compose:**
```bash
cd firebase/functions
docker-compose up --build
```

2. **Environment Variables:**
Create a `.env` file in the functions directory:
```env
OPENAI_API_KEY=your_openai_api_key_here
FIREBASE_PROJECT_ID=your_firebase_project_id
MAX_INSTANCES=5
CORS_ORIGINS=*
AI_TEMPERATURE=0.7
REQUEST_TIMEOUT=10
MAX_SEARCH_RESULTS=5
MAX_SCRAPED_CONTENT_LENGTH=1000
```

### Manual Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Set environment variables:**
```bash
export OPENAI_API_KEY="your_key_here"
export FIREBASE_PROJECT_ID="your_project_id"
```

3. **Run locally:**
```bash
python main.py
```

## 🐳 Containerization

### Building the Docker Image

```bash
docker build -t wutzup-functions .
```

### Running the Container

```bash
docker run -p 8080:8080 \
  -e OPENAI_API_KEY="your_key" \
  -e FIREBASE_PROJECT_ID="your_project" \
  wutzup-functions
```

### Docker Compose for Development

```bash
# Start services
docker-compose up

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📋 API Endpoints

### Health & Testing
- `GET /health_check` - Health check endpoint
- `POST /test_notification` - Test push notifications

### Translation & AI
- `POST /translate_text` - Text translation
- `POST /message_context` - Cultural context analysis
- `POST /language_tutor` - AI language tutor
- `POST /generate_response_suggestions` - Response suggestions

### Media & Research
- `POST /generate_gif` - DALL-E GIF generation
- `POST /conduct_research` - Web research and summarization

### Tutor AI
- `POST /generate_tutor_greeting` - Initial tutor greeting
- `POST /generate_tutor_response` - Tutor conversation response

## ⚙️ Configuration

All configuration is managed through the `config.py` file and environment variables:

- **OpenAI Integration**: API key and model settings
- **CORS Settings**: Cross-origin request configuration
- **Performance**: Instance limits and timeouts
- **AI Models**: Temperature and model selection
- **Image Processing**: GIF settings and optimization

## 🔧 Maintenance

### Adding New Functions

1. Create handler in appropriate `handlers/` file
2. Import in `main.py`
3. Add tests and documentation
4. Update this README

### Utility Functions

- Add reusable utilities to `utils/` directory
- Follow existing patterns for error handling and logging
- Include type hints and docstrings

### Configuration Changes

- Update `config.py` for new settings
- Add environment variable validation
- Update Docker and compose files if needed

## 🚀 Deployment

### Firebase Functions

```bash
# Deploy to Firebase
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:functionName
```

### Docker Deployment

```bash
# Build production image
docker build -t wutzup-functions:latest .

# Push to registry
docker tag wutzup-functions:latest your-registry/wutzup-functions:latest
docker push your-registry/wutzup-functions:latest
```

## 📊 Monitoring

- **Logs**: All functions include comprehensive logging
- **Health Checks**: Built-in health check endpoints
- **Error Handling**: Graceful error handling with proper HTTP status codes
- **Performance**: Configurable instance limits and timeouts

## 🔒 Security

- **Environment Variables**: Sensitive data in environment variables only
- **CORS**: Configurable cross-origin settings
- **Input Validation**: All endpoints validate input data
- **Error Messages**: No sensitive data in error responses

## 📝 Logging

All functions use structured logging with:
- Function name and operation
- Request/response details
- Error tracking with stack traces
- Performance metrics

Example log format:
```
INFO: 🎓 Language tutor: es message from user
INFO: ✅ Language tutor response generated (156 chars)
```
