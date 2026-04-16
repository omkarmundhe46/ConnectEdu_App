# 🎓 ConnectedU – Smart Club And Event Coordination Platform (Microservices Architecture)

ConnectedU is a **modern, scalable college management platform** built using **Spring Boot Microservices** and a **Flutter frontend**. It enables seamless interaction between students, clubs, and administrators with features like event management, real-time discussions, certificate generation, and notifications.

---

<img width="408" height="740" alt="Screenshot_20260320_105826" src="https://github.com/user-attachments/assets/430a6617-fd0d-4308-917a-29169001d92e" />
<img width="408" height="740" alt="Screenshot_20260320_105820" src="https://github.com/user-attachments/assets/f7392f44-3326-4d34-a0d2-d5bf5d29d346" />
<img width="408" height="740" alt="Screenshot_20260320_105803" src="https://github.com/user-attachments/assets/7c7cc0f1-8323-4560-8ea1-50ea7ddfe27a" />
<img width="408" height="740" alt="Screenshot_20260320_105737" src="https://github.com/user-attachments/assets/f9f74b03-612a-4015-ad08-e6d4a454d46e" />
<img width="408" height="740" alt="Screenshot_20260320_105712" src="https://github.com/user-attachments/assets/816953af-61c1-4596-a488-13adb1688dfc" />
<img width="408" height="740" alt="Screenshot_20260320_105705" src="https://github.com/user-attachments/assets/e4f3695a-d581-497a-aa8b-b06a89f1bef7" />
<img width="408" height="740" alt="Screenshot_20260320_105701" src="https://github.com/user-attachments/assets/631d62f5-771f-4cd0-ba39-29636e6acfba" />
<img width="408" height="740" alt="Screenshot_20260320_105654" src="https://github.com/user-attachments/assets/f3bdfb9f-26c2-4b2e-b0fb-607894a4df5c" />
<img width="408" height="740" alt="Screenshot_20260320_105644" src="https://github.com/user-attachments/assets/7258e2e7-74ea-45c2-9966-1a7ab4c1b96e" />
<img width="408" height="740" alt="Screenshot_20260320_105352" src="https://github.com/user-attachments/assets/472f48d4-caaa-4830-ba0d-19a94fc2b88b" />
<img width="408" height="740" alt="Screenshot_20260320_105340" src="https://github.com/user-attachments/assets/18dfbdaa-69c3-4844-962f-300e2310b705" />
<img width="408" height="740" alt="Screenshot_20260320_110732" src="https://github.com/user-attachments/assets/29fe4d25-0100-48a9-b9f1-f555aa94bb45" />
<img width="408" height="740" alt="Screenshot_20260320_110702" src="https://github.com/user-attachments/assets/5578ce9f-0e80-48ca-b3a2-fa0aabb54c95" />
<img width="408" height="740" alt="Screenshot_20260320_105945" src="https://github.com/user-attachments/assets/3f226846-1643-4f24-9bd3-aec3f2c5abcc" />
<img width="408" height="740" alt="Screenshot_20260320_105926" src="https://github.com/user-attachments/assets/0645d6dd-b883-4232-a4c8-c0331a90b187" />
<img width="408" height="740" alt="Screenshot_20260320_105912" src="https://github.com/user-attachments/assets/896c94ef-93a6-4003-a001-a9e410ccd1b8" />
<img width="408" height="740" alt="Screenshot_20260320_105853" src="https://github.com/user-attachments/assets/7c704967-2243-4fb3-8d7e-4b1392ece531" />


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
