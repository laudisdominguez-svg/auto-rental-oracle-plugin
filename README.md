# auto-rental-oracle-plugin
# 🚗 Auto-Rental Oracle Plugins

Sistema descentralizado de agregación de precios para plataforma de renta de autos en red privada Besu. Implementa verificación criptográfica, auditoría completa y validación inteligente de datos.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Arquitectura](#arquitectura)
- [Instalación](#instalación)
- [Uso](#uso)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Seguridad](#seguridad)
- [Contribuciones](#contribuciones)

## ✨ Características

### Interfaz IAggregator (Estándar)
- ✅ **Reportes con Firma**: `reportPrice()`, `reportDailyRate()`
- ✅ **Lectura de Datos**: `getPrice()`, `getDailyRate()`, `calculateRentalCost()`
- ✅ **Validación Inteligente**: `validateData()` con tolerancia configurable
- ✅ **Trazabilidad**: `getDataSource()`, `getLastUpdateTime()`
- ✅ **Control de Acceso**: `isAuthorizedReporter()`

### RentalOracle (Implementación)
- 🔐 **Autorización de Proveedores**: Solo proveedores verificados pueden reportar
- 📊 **Auditoría Completa**: Historial de todas las actualizaciones
- 🎯 **Validación de Tolerancia**: Rango configurable de aceptación de precios
- ⛓️ **Verificación Criptográfica**: Soporte para firmas ECDSA
- 🏠 **Control Ownable**: Gestión centralizada de configuración

## 🏗️ Arquitectura

```
IAggregator (Interface)
    ↓
RentalOracle (Implementation)
    ├─ Ownable (Control de acceso)
    ├─ ECDSA (Verificación de firmas)
    └─ Storage (Auditoría y datos)
```

## 📦 Instalación

### Requisitos Previos
- Node.js 16+
- Hardhat
- npm o yarn

### Pasos

1. **Clonar repositorio**
```bash
git clone <repo-url>
cd auto-rental-oracle-plugins
```

2. **Instalar dependencias**
```bash
npm install
```

3. **Compilar contratos**
```bash
npm run compile
```

4. **Ejecutar tests**
```bash
npm test
```

5. **Ver cobertura**
```bash
npm run test:coverage
```

## 🚀 Uso

### Despliegue Local

```bash
# Iniciar nodo Hardhat
npm run node

# En otra terminal, desplegar
npm run deploy
```

### Despliegue en Besu

```bash
# Configurar en hardhat.config.js
networks: {
  besuPrivate: {
    url: "http://localhost:8545",
    accounts: [process.env.PRIVATE_KEY]
  }
}

# Desplegar
npx hardhat run scripts/deploy.js --network besuPrivate
```

### Interacción en Consola

```javascript
// En hardhat console
const contract = await ethers.getContractAt("RentalOracle", "0x...");

// 1. Autorizar proveedor
await contract.authorizeProvider("0x...");

// 2. Reportar precio
await contract.reportPrice(
  "Tesla Model 3",
  ethers.parseUnits("50000", 8),
  "0x"
);

// 3. Obtener precio
const price = await contract.getPrice("Tesla Model 3");
console.log(ethers.formatUnits(price, 8)); // 50000.0

// 4. Validar datos
const isValid = await contract.validateData(
  "Tesla Model 3",
  ethers.parseUnits("50000", 8),
  10 // 10% tolerancia
);
console.log(isValid); // true/false

// 5. Calcular costo de renta
const cost = await contract.calculateRentalCost("Tesla Model 3", 5);
console.log(ethers.formatUnits(cost, 2)); // total USD
```

## 📚 API Reference

### Funciones de Lectura

#### `getPrice(string model) → uint256`
Retorna el precio actual del modelo en USD (8 decimales).

```solidity
uint256 price = rentalOracle.getPrice("Tesla Model 3");
// Retorna: 50000000000000 (50000 USD con 8 decimales)
```

#### `getDailyRate(string model) → uint256`
Retorna la tasa diaria de renta en USD (2 decimales).

```solidity
uint256 rate = rentalOracle.getDailyRate("Tesla Model 3");
// Retorna: 15000 (150 USD con 2 decimales)
```

#### `calculateRentalCost(string model, uint256 days) → uint256`
Calcula el costo total de renta.

```solidity
uint256 cost = rentalOracle.calculateRentalCost("Tesla Model 3", 5);
// Retorna: dailyRate * 5
```

#### `getLastUpdateTime(string model) → uint256`
Retorna timestamp de la última actualización.

```solidity
uint256 timestamp = rentalOracle.getLastUpdateTime("Tesla Model 3");
```

#### `getDataSource(string model) → (address, uint256)`
Retorna proveedor y número de actualizaciones.

```solidity
(address provider, uint256 updateCount) = rentalOracle.getDataSource("Tesla Model 3");
```

#### `validateData(string model, uint256 expectedPrice, uint256 tolerance) → bool`
Valida si el precio actual está dentro de la tolerancia.

```solidity
bool isValid = rentalOracle.validateData(
  "Tesla Model 3",
  ethers.parseUnits("50000", 8),
  10  // 10%
);
```

#### `isAuthorizedReporter(address reporter) → bool`
Verifica si un reportador está autorizado.

```solidity
bool isAuth = rentalOracle.isAuthorizedReporter(msg.sender);
```

### Funciones de Actualización

#### `reportPrice(string model, uint256 price, bytes signature)`
Reporta un nuevo precio (solo autorizado).

```solidity
await rentalOracle.reportPrice(
  "Tesla Model 3",
  ethers.parseUnits("50000", 8),
  "0x..."
);
```

**Emite:** `PriceUpdated(model, price, reporter, timestamp)`

#### `reportDailyRate(string model, uint256 rate, bytes signature)`
Reporta una nueva tasa diaria (solo autorizado).

```solidity
await rentalOracle.reportDailyRate(
  "Tesla Model 3",
  ethers.parseUnits("150", 2),
  "0x..."
);
```

**Emite:** `DailyRateUpdated(model, rate, reporter, timestamp)`

### Funciones de Administración (Solo Owner)

#### `authorizeProvider(address provider)`
Autoriza a un nuevo proveedor.

```solidity
await rentalOracle.authorizeProvider("0x...");
```

#### `revokeProvider(address provider)`
Revoca autorización de un proveedor.

```solidity
await rentalOracle.revokeProvider("0x...");
```

#### `setDefaultTolerance(uint256 tolerance)`
Configura tolerancia por defecto (1-100).

```solidity
await rentalOracle.setDefaultTolerance(15); // 15%
```

### Funciones de Auditoría

#### `getPriceHistory() → PriceUpdate[]`
Retorna historial completo de actualizaciones.

```solidity
PriceUpdate[] memory history = rentalOracle.getPriceHistory();
```

#### `getAvailableModels() → string[]`
Retorna lista de todos los modelos.

```solidity
string[] memory models = rentalOracle.getAvailableModels();
```

#### `getCarData(string model) → CarData`
Retorna estructura completa de datos del auto.

```solidity
CarData memory carData = rentalOracle.getCarData("Tesla Model 3");
```

## 🧪 Testing

### Ejecutar todos los tests
```bash
npm test
```

### Ejecutar tests específicos
```bash
npx hardhat test tests/aggregator.test.js
```

### Cobertura de código
```bash
npm run test:coverage
```

### Tests Incluidos
- ✅ Despliegue e inicialización
- ✅ Gestión de proveedores
- ✅ Reportes de precio y tasa
- ✅ Lectura de datos
- ✅ Validación de datos
- ✅ Auditoría y trazabilidad
- ✅ Casos límite y errores
- ✅ Integración completa

**Total: 40+ casos de prueba**

## 🔐 Seguridad

### Implementado
- ✅ Control de acceso: `Ownable` + `authorizedProviders`
- ✅ Validación de entrada: modelos, precios, tolerancia
- ✅ Auditoría: historial completo de cambios
- ✅ Prevención de direcciones nulas
- ✅ Prevención de valores negativos/cero

### A Implementar
- ⏳ ECDSA completo para firmas criptográficas
- ⏳ Rate limiting por proveedor
- ⏳ Agregación de múltiples fuentes (promedio ponderado)
- ⏳ Circuit breaker para anomalías extremas

## 📝 Eventos

```solidity
event PriceUpdated(
  string indexed carModel,
  uint256 newPrice,
  address indexed reporter,
  uint256 timestamp
);

event DailyRateUpdated(
  string indexed carModel,
  uint256 newRate,
  address indexed reporter,
  uint256 timestamp
);

event DataValidationFailed(
  string indexed carModel,
  address indexed reporter,
  string reason
);

event ProviderAuthorized(address indexed provider);
event ProviderRevoked(address indexed provider);
event ToleranceUpdated(uint256 newTolerance);
```

## 🔧 Configuración

### hardhat.config.js
```javascript
solidity: {
  version: "0.8.0",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
},
paths: {
  sources: "./contracts",
  tests: "./tests",
  cache: "./cache",
  artifacts: "./artifacts"
}
```

## 📊 Estructura de Proyecto

```
auto-rental-oracle-plugins/
├── contracts/
│   ├── aggregator.sol          # Interfaz IAggregator
│   ├── RentalOracle.sol        # Implementación
│   └── ...
├── tests/
│   ├── aggregator.test.js      # Tests completos (40+ casos)
│   └── ...
├── scripts/
│   ├── deploy.js               # Script de despliegue
│   └── ...
├── docs/
│   ├── ARQUITECTURA.md         # Documentación técnica
│   ├── README.md               # Este archivo
│   └── ...
├── hardhat.config.js           # Configuración Hardhat
├── package.json                # Dependencias
└── .gitignore                  # Exclusiones Git
```

## 🚀 Próximos Pasos

1. **Implementar ECDSA completo**
   ```solidity
   bytes32 messageHash = keccak256(abi.encodePacked(_carModel, _price));
   address signer = messageHash.toEthSignedMessageHash().recover(_signature);
   require(signer == msg.sender, "Invalid signature");
   ```

2. **Agregar agregación de múltiples fuentes**
   ```solidity
   function aggregatePrice(string memory model) → uint256
   // Promedio ponderado de múltiples reportes
   ```

3. **Implementar circuit breaker**
   ```solidity
   function isPriceAnomaly(uint256 newPrice, uint256 oldPrice) → bool
   // Detectar cambios extremos
   ```

4. **Integración con Chainlink**
   - Usar Chainlink Price Feeds
   - VRF para selección de reportadores

## 📞 Soporte

- Revisar documentación en `docs/ARQUITECTURA.md`
- Ejecutar tests para verificar funcionamiento
- Consultar comentarios NatSpec en código

## 📄 Licencia

MIT

---

**Versión:** 1.0.0  
**Última actualización:** 2026-04-26  
**Estado:** ✅ Producción
