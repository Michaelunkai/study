# TovPlay Frontend

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

🎮 Your go-to platform to find gamers, manage game requests, and schedule sessions seamlessly.

## ✨ Features

- **🤝 Player Discovery**: Find & connect with fellow gamers
- **🗓️ Session Scheduling**: Organize your upcoming game sessions effortlessly  
- **📬 Game Requests**: Send and receive game invites with ease
- **👤 Personalized Profiles**: Customize and explore detailed player profiles
- **🌐 Multi-language Support**: Experience the app in your preferred language

## 🛠️ Tech Stack

- **Framework**: React.js with Vite
- **Styling**: Tailwind CSS
- **UI Components**: Shadcn UI
- **State Management**: Redux Toolkit
- **HTTP Client**: Axios
- **Testing**: Vitest, Cypress
- **Containerization**: Docker with Nginx

## 📋 Prerequisites

- Node.js 18+
- npm or yarn

## 🔧 Installation

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/8GSean/tovplay-frontend.git
   cd tovplay-frontend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Run the application**
   ```bash
   # Option 1: Using npm
   npm run dev
   
   # Option 2: Using the one-liner
   run-frontend.bat
   ```

4. **Access the application**: http://localhost:5173

### Docker Development

1. **Build and run with Docker**
   ```bash
   docker build -t tovplay-frontend .
   docker run -p 80:80 tovplay-frontend
   ```

## 🏃 Quick Start

Run the frontend in one command:
```bash
run-frontend.bat
```

Run both backend and frontend:
```bash
# From the parent directory
run-both.bat
```

## 🧪 Testing

```bash
# Run unit tests
npm run test

# Run E2E tests
npm run test:e2e

# Run tests with coverage
npm run test:coverage
```

## 🔍 Code Quality

```bash
# Lint code
npm run lint

# Fix linting issues
npm run lint:fix

# Type checking
npm run type-check

# Format code
npm run format:write
```

## 🏗️ Build

```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

## 📁 Project Structure

```
tovplay-frontend/
├── .github/workflows/          # GitHub Actions
├── src/
│   ├── components/            # Reusable UI components
│   ├── pages/                # Application pages
│   ├── stores/               # Redux stores
│   ├── api/                  # API services
│   ├── hooks/                # Custom React hooks
│   └── utils/                # Utility functions
├── cypress/                  # E2E tests
├── public/                   # Static assets
├── Dockerfile               # Container configuration
├── nginx.conf              # Nginx configuration
└── package.json            # Dependencies and scripts
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Production**: https://tovplay.com
- **Staging**: https://staging.tovplay.com
- **Backend API**: https://api.tovplay.com

## 📞 Support

For support and questions, please open an issue in this repository.

---



________________________________________________________________________________________________
