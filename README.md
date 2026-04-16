# 🎓 ConnectedU – Smart Club And Event Coordination Platform (Microservices Architecture)

ConnectedU is a **modern, scalable college management platform** built using **Spring Boot Microservices** and a **Flutter frontend**. It enables seamless interaction between students, clubs, and administrators with features like event management, real-time discussions, certificate generation, and notifications.

---

# 🚀 Features

### 👨‍💼 College Admin

* Create & manage clubs
* Assign club admins
* View analytics dashboard
* Post announcements

### 🧑‍💻 Club Admin

* Manage club members
* Create & manage events
* Add meeting links
* Select certificate templates
* Export participant data (Excel)
* Manage discussions

### 👥 Club Members

* Participate in event discussions
* Engage in real-time chat

### 🎓 Students / Users

* Register & login
* Browse clubs & events
* Register for events
* Make payments
* Download certificates

---

# 🏗️ Architecture Overview

ConnectedU follows a **Microservices Architecture**:

* Each service is **independent**
* Communicates via **REST (Feign)** and **Kafka (event-driven)**
* Uses **Eureka for service discovery**
* API Gateway acts as a **single entry point**

---

# 🔧 Tech Stack

### Backend

* Java 21
* Spring Boot
* Spring Security (JWT)
* Spring Cloud (Eureka, Gateway, Feign)
* WebSocket (Real-time chat)
* Kafka (Event-driven communication)

### Frontend

* Flutter (Dart)

### Database

* MySQL (DB per service)

### Cloud & Storage

* AWS S3 (file storage)

### Messaging & Email

* Apache Kafka
* SMTP (Email notifications)

---

# 🧩 Microservices Breakdown

### 1. User Service

* Authentication & authorization (JWT)
* User management
* Email verification via Kafka

---

### 2. Club Service

* Club creation & management
* Member management
* Role assignment

---

### 3. Event Service

* Event creation & management
* Participant registration
* Analytics

---

### 4. Discussion Service 💬

* Real-time chat using WebSocket
* Message persistence (DB)
* File sharing via AWS S3
* Membership validation

---

### 5. Certificate Service 🏆

* Certificate generation (JasperReports)
* Template-based certificates
* Upload to AWS S3
* Kafka event for notifications

---

### 6. Notification Service 📧

* Email notifications
* Kafka consumers
* Event-based messaging (user, event, certificate)

---

### 7. Payment Service 💳

* Razorpay integration
* Secure payment handling

---

### 8. API Gateway 🚪

* Central entry point
* Routing requests
* Load balancing

---

### 9. Service Registry (Eureka)

* Service discovery
* Dynamic service resolution

---

# 🔄 System Flow

```text
Register → Login → Home → Clubs → Events → Register Event → Payment → Certificate Download
```

---

# 🔐 Security

* JWT-based authentication
* Role-based authorization (RBAC)
* Stateless architecture
* Secure APIs using Spring Security

---

# 📡 Communication Between Services

| Type         | Technology   | Usage                    |
| ------------ | ------------ | ------------------------ |
| Synchronous  | Feign Client | Service-to-service calls |
| Asynchronous | Kafka        | Notifications, events    |
| Real-time    | WebSocket    | Chat system              |

---

# 💬 Discussion (Chat) Flow

1. User sends message via WebSocket
2. JWT validated
3. Event + membership verified
4. Message saved in DB
5. Broadcast to all users

---

# 📁 File Upload Flow

1. User uploads file
2. File stored in AWS S3
3. URL saved in database
4. Shared in chat

---

# 📜 Certificate Flow

1. Event completed
2. Certificate generated (JasperReports)
3. Uploaded to AWS S3
4. Kafka event triggered
5. Notification service sends email

---

# 📦 Project Structure

```
ConnectedU/
 ├── api-gateway/
 ├── service-registry/
 ├── user-service/
 ├── club-service/
 ├── event-service/
 ├── discussion-service/
 ├── certificate-service/
 ├── notification-service/
 ├── payment-service/
 ├── frontend (Flutter)
```

---

# ⚙️ Setup Instructions

### 1. Clone Repository

```bash
git clone https://github.com/your-username/connectedu.git
```

---

### 2. Start Services in Order

1. Service Registry (Eureka)
2. API Gateway
3. User Service
4. Other Services

---

### 3. Configure Environment Variables

* DB credentials
* JWT secret
* AWS credentials
* Kafka config
* Razorpay keys

---

### 4. Run Application

```bash
mvn spring-boot:run
```

---

### 5. Run Flutter App

```bash
flutter run
```

---

# 📊 Key Highlights

* Scalable microservices architecture
* Real-time chat system
* Event-driven communication (Kafka)
* Secure authentication (JWT)
* Cloud storage (AWS S3)
* Payment integration
* Certificate automation

---

# 🚀 Future Enhancements

* Push notifications (Firebase)
* AI chatbot integration
* Recommendation system
* Advanced analytics dashboard
* Kubernetes deployment

---

# 👨‍💻 Author

**Omkar Mundhe**
Java Full Stack Developer
Skills: Spring Boot, Microservices, React/Flutter, AWS, Kafka

---

# ⭐ Support

If you like this project:

* ⭐ Star this repository
* 🍴 Fork it
* 🛠️ Contribute

---

# 📜 License

This project is licensed under the MIT License.
