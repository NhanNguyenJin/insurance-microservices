# Case Study: Hệ thống bán bảo hiểm với kiến trúc Microservices trên .NET Core

Bài thực hành tổ hợp (Thực hành số 4 → 5 → 6): **Case study Cài đặt kiến trúc Microservices trên môi trường .NET Core (Bài toán đại lý bảo hiểm)**.

Hệ thống giúp các đại lý bảo hiểm bán sản phẩm bảo hiểm: xem danh mục sản phẩm, tính giá, tạo báo giá, chuyển báo giá thành hợp đồng (policy), quản lý dashboard thống kê và chat giữa các nhân viên hỗ trợ.

## Kiến trúc

```
Web (VueJS SPA) / BlazorWasmClient ──► AgentPortalApiGateway (Ocelot + Eureka + CacheManager)
                                              │
              ┌───────────────┬───────────────┼────────────────┬─────────────┐
              ▼               ▼               ▼                ▼             ▼
        AuthService     ProductService   PolicyService   PricingService  DashboardService
              │               │               │               │             │
              │               │               ▼               │        ElasticSearch
              │               │          RabbitMQ ──► ChatService        (NEST/ES 8)
              │               │               │         (SignalR)
              ▼               ▼               ▼
        PostgreSQL     PostgreSQL      Marten/PostgreSQL

Service Discovery: Eureka Server (Spring Boot, port 8761)
```

- Mỗi microservice gồm tối đa 3 dự án: **API definition** (lệnh/thực thi/sự kiện/DTO), **Implementation** (handlers, controllers, listeners, data access) và **Test**.
- Giao tiếp ngoài: REST qua API Gateway (Ocelot, định tuyến qua **Eureka service discovery**, JWT bảo mật, cache bằng **CacheManager**).
- Giao tiếp nội bộ bất đồng bộ: RabbitMQ (EasyNetQ) — các sự kiện vòng đời policy.

## Danh sách thành phần

| Dự án | Loại | Vai trò |
|---|---|---|
| `AgentPortalApiGateway` | .NET 8 Web + Ocelot | API Gateway: định tuyến, bảo mật JWT, Eureka discovery, cache |
| `AuthService` | .NET 8 Web | Xác thực người dùng, cấp JWT token, quản lý tài khoản đại lý |
| `ChatService` / `ChatService.Api` | .NET 8 Web / ClassLib | Chat giữa nhân viên hỗ trợ qua SignalR; nhận sự kiện `PolicyCreated` để gửi thông báo |
| `DashboardService` / `DashboardService.Api` / `DashboardService.Test` | .NET 8 Web / ClassLib / xUnit | Thống kê bán hàng (tổng số, xu hướng theo thời gian, theo đại lý) đọc từ ElasticSearch |
| `PricingService` / `PricingService.Api` | .NET 8 Web / ClassLib | Tính giá sản phẩm bảo hiểm theo tariff + rules (DynamicExpresso); đăng ký Eureka |
| `PricingService.Test` / `PricingService.IntegrationTest` | xUnit | Kiểm thử đơn vị (tariff, handler, controller) + tích hợp (Testcontainers + Alba) |
| `PolicyService.Api` | ClassLib | Định nghĩa lệnh/truy vấn/sự kiện vòng đời Policy (CreateOffer, CreatePolicy, PolicyCreated...) |
| `ProductService` / `ProductService.Api` / `ProductService.Test` | .NET 8 Web / ClassLib / xUnit | Danh mục sản phẩm bảo hiểm; lưu dữ liệu dưới dạng JSON; kiểm thử unit |
| `PaymentService` / `PaymentService.Api` / `PaymentService.Test` | .NET 8 Web / ClassLib / xUnit | Quản lý tài khoản chính sách và payments; dùng **Marten** (PostgreSQL document DB + event store); nhận sự kiện vòng đời Policy qua RabbitMQ |
| `ProductService.Api` | ClassLib | Định nghĩa truy vấn danh mục sản phẩm |
| `PolicySearchService.Api` | ClassLib | Định nghĩa truy vấn tìm kiếm policy trên ElasticSearch |
| `BlazorWasmClient` | Blazor WASM | Giao diện spa Blazorise cho đại lý |
| `Web` | VueJS SPA | Giao diện web agent portal |
| `eureka-server` | Spring Boot | Service Registry (port 8761) |
| `postgres` | Docker | PostgreSQL + script tạo các CSDL |
| `scripts` | shell/bat + docker-compose | Script build / chạy hạ tầng (infra.yml) và chạy app (app.yml) |

## Bài thực hành số 6 — Nội dung mới thực hiện

1. **Task #1 — API Gateway với Ocelot** (`AgentPortalApiGateway`):
   - Gói NuGet: `Ocelot` + `Ocelot.Provider.Eureka` + `Ocelot.Cache.CacheManager`.
   - `ocelot.json`: `GlobalConfiguration` với `RequestIdKey`, `AdministrationPath`, `UseServiceDiscovery`, `ServiceDiscoveryProvider: Eureka @ localhost:8761`; các `Routes` định tuyến qua `ServiceName` (ProductService, PolicyService, PolicySearchService, DashboardService) kèm cache `TtlSeconds`, JWT `AuthenticationOptions`, `RouteClaimsRequirement`.
   - `Program.cs`: `AddOcelot().AddEureka().AddCacheManager(x => x.WithDictionaryHandle())` + `UseOcelot()`.
   - `appsettings.json`: cấu hình `Spring.Eureka.Client` (`ShouldRegisterWithEureka: false`, `serviceUrl http://localhost:8761/eureka/`).
2. **Task #2 — AuthService**: bổ sung đầy đủ code (1 thư mục dịch vụ).
3. **Task #3 — Chat service**: bổ sung 2 thư mục (`ChatService`, `ChatService.Api`).
4. **Task #4 — Dashboard service**: bổ sung 3 thư mục (`DashboardService`, `DashboardService.Api`, `DashboardService.Test`).

## Bài thực hành số 7 — Nội dung mới thực hiện

1. **Task #1 — Thêm Marten vào dự án**:
   - Gói NuGet `Marten 7.19.1` đã được thêm vào `PaymentService` (PostgreSQL làm document database + event store, tuân thủ ACID, LINQ mở rộng); trước đó `PricingService` đã dùng Marten.
2. **Task #2 — PaymentService**: bổ sung 3 thư mục (`PaymentService`, `PaymentService.Api`, `PaymentService.Test`):
   - Ghi nhận sự kiện vòng đời policy qua RabbitMQ, tạo/ghi tài khoản chính sách (`MartenPolicyAccountRepository`), phân tích payments đến và gán vào tài khoản phù hợp.
3. **Task #3 — ProductService**: bổ sung 3 thư mục (`ProductService`, `ProductService.Api`, `ProductService.Test`):
   - Danh mục sản phẩm (Travel/House/Farm/Car) với các tham số tùy chỉnh, covers và câu hỏi định giá.

➡️ **Kết quả build toàn solution: 0 Error** (chỉ còn warnings do code mẫu gốc).

## Chạy hệ thống

### 1. Hạ tầng (Docker)
```bash
cd scripts
docker compose -f infra.yml up -d
```
(hạ tầng gồm PostgreSQL, RabbitMQ, ElasticSearch; Eureka chạy bằng spring boot trong `eureka-server`)

### 2. Tạo CSDL PostgreSQL
Chạy script `postgres/createdatabases.sql` trên PostgreSQL.

### 3. Eureka Server
```bash
cd eureka-server/eureka-server
.\gradlew bootRun
```
Mở `http://localhost:8761` để xem các dịch vụ đã đăng ký.

### 4. Build + chạy từng dịch vụ
```bash
dotnet build DotNetMicroservicesPoc.sln
dotnet run --project AgentPortalApiGateway   # Gateway :8099
dotnet run --project AuthService
dotnet run --project ChatService
dotnet run --project DashboardService
dotnet run --project PricingService
```

### 5. Kiểm thử
```bash
dotnet test PricingService.Test
dotnet test DashboardService.Test
```
> `PricingService.IntegrationTest` và `DashboardService.Test` dùng Testcontainers nên cần Docker đang chạy.

## Điều kiện cần có

- .NET 8 SDK (build bằng .NET 9 SDK cũng được)
- Docker Desktop (RabbitMQ, ElasticSearch, PostgreSQL, Testcontainers)
- PostgreSQL >= 10, ElasticSearch >= 6, JRE cho Eureka Server
