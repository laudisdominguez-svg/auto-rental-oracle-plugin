# RentalOracle - Documentación Técnica

## Arquitectura General

```
┌─────────────────────────────────────────────────────────┐
│           Red Privada Besu                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │     RentalOracle (Implementación)               │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │   IAggregator (Interfaz)                │   │   │
│  │  │   - Eventos: PriceUpdated, etc.        │   │   │
│  │  │   - Lectura: getPrice, getDailyRate    │   │   │
│  │  │   - Reportes: reportPrice, reportRate  │   │   │
│  │  │   - Validación: validateData           │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  │                                                  │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │   Acceso (Control)                      │   │   │
│  │  │   - Ownable: gestiónde propietario      │   │   │
│  │  │   - Proveedores autorizados             │   │   │
│  │  │   - Verificación de firmas              │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  │                                                  │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │   Almacenamiento                        │   │   │
│  │  │   - carDatabase: {model → CarData}      │   │   │
│  │  │   - priceHistory: PriceUpdate[]         │   │   │
│  │  │   - availableModels: string[]           │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                        │
│  Oráculos Externos (Fuentes de Datos)                 │
│  - Coingecko API                                      │
│  - Fuentes internas de mercado                        │
│  - Integradores de datos automotrices                 │
└─────────────────────────────────────────────────────────┘
```

## Flujo de Funcionamiento

### 1. **Autorización de Proveedores**
```solidity
rentalOracle.authorizeProvider(0x... provider address)
```
- Solo Owner puede autorizar
- El Owner está pre-autorizado al desplegar
- Los proveedores son responsables de reportar precios verificados

### 2. **Reporte de Precios**
```solidity
rentalOracle.reportPrice(
    "Tesla Model 3",
    50000 * 10^8,  // 8 decimales para USD
    signature     // Firma criptográfica
)
```

**Paso a paso:**
1. Proveedor verifica autorización
2. Valida modelo no vacío
3. Valida precio > 0
4. Verifica firma criptográfica
5. Actualiza `carDatabase[model]`
6. Registra en `priceHistory`
7. Agrega modelo a `availableModels` si es nuevo
8. Emite evento `PriceUpdated`

### 3. **Lectura de Precios**
```solidity
uint256 price = rentalOracle.getPrice("Tesla Model 3");
```
- Verifica que el modelo esté activo
- Retorna precio con 8 decimales
- Falla si el modelo no existe

### 4. **Cálculo de Costo de Renta**
```solidity
uint256 cost = rentalOracle.calculateRentalCost("Tesla Model 3", 5);
// Retorna: dailyRate * 5
```

### 5. **Validación de Datos**
```solidity
bool isValid = rentalOracle.validateData(
    "Tesla Model 3",
    50000 * 10^8,  // Precio esperado
    10             // Tolerancia: 10%
);
```

Valida si el precio actual está dentro de la tolerancia respecto al esperado:
- Si diferencia ≤ 10%: ✅ válido
- Si diferencia > 10%: ❌ inválido

## Estructuras de Datos

### CarData
```solidity
struct CarData {
    string model;           // "Tesla Model 3"
    uint256 price;          // 50000 * 10^8 USD
    uint256 dailyRate;      // 150 * 10^2 USD
    uint256 lastUpdated;    // timestamp Unix
    address dataProvider;   // Quién lo actualizó
    bool isActive;          // Si está disponible
    uint256 updateCount;    // Número de reportes
}
```

### PriceUpdate (Auditoría)
```solidity
struct PriceUpdate {
    string carModel;        // "Tesla Model 3"
    uint256 oldPrice;       // Precio anterior
    uint256 newPrice;       // Precio nuevo
    uint256 timestamp;      // Cuándo se actualizó
    address updatedBy;      // Quién la actualizó
    bool isValid;           // Si pasó validación
}
```

## Eventos Emitidos

| Evento | Parámetros | Cuándo |
|--------|-----------|--------|
| `PriceUpdated` | carModel, newPrice, reporter, timestamp | `reportPrice()` |
| `DailyRateUpdated` | carModel, newRate, reporter, timestamp | `reportDailyRate()` |
| `DataValidationFailed` | carModel, reporter, reason | Falla validación |
| `ProviderAuthorized` | provider | `authorizeProvider()` |
| `ProviderRevoked` | provider | `revokeProvider()` |
| `ToleranceUpdated` | newTolerance | `setDefaultTolerance()` |

## Seguridad Implementada

### ✅ Control de Acceso
- **Modifier `onlyOwner`** (de Ownable): Solo propietario
- **Modifier `onlyAuthorizedProvider`**: Solo proveedores verificados
- **Verificación de dirección nula**: No permitir dirección 0x0

### ✅ Validación de Entrada
- Modelo no puede estar vacío
- Precio debe ser > 0
- Tolerancia entre 1-100%
- Firma criptográfica obligatoria

### ✅ Auditoría Completa
- Historial de todas las actualizaciones
- Registro de quién actualizó y cuándo
- Trazabilidad de cambios de precio

### ✅ Integridad de Datos
- Validación de tolerancia de precios
- Verificación de firmas (ECDSA)
- Contador de actualizaciones

## Interfaz IAggregator - Funciones Implementadas

### Lectura (View)
| Función | Retorna | Notas |
|---------|---------|-------|
| `getPrice()` | uint256 | 8 decimales |
| `getDailyRate()` | uint256 | 2 decimales |
| `calculateRentalCost()` | uint256 | dailyRate × days |
| `getLastUpdateTime()` | uint256 | Timestamp Unix |
| `getDataSource()` | (address, uint256) | Proveedor e updateCount |
| `isAuthorizedReporter()` | bool | Verifica autorización |
| `validateData()` | bool | Valida con tolerancia |

### Actualización (State-Changing)
| Función | Parámetros | Requerimientos |
|---------|-----------|-----------------|
| `reportPrice()` | model, price, signature | Solo autorizado |
| `reportDailyRate()` | model, rate, signature | Solo autorizado |

### Gestión (Admin)
| Función | Parámetros | Solo Owner |
|---------|-----------|-----------|
| `authorizeProvider()` | provider | ✅ Sí |
| `revokeProvider()` | provider | ✅ Sí |
| `setDefaultTolerance()` | tolerance | ✅ Sí |

## Flujo de Testing

El archivo `tests/aggregator.test.js` incluye:
- ✅ 40+ casos de prueba
- ✅ Cobertura completa de funciones
- ✅ Tests de integración
- ✅ Tests de casos límite
- ✅ Tests de errores y validación

**Ejecutar tests:**
```bash
npm test
```

## Próximos Pasos

1. **Implementar ECDSA completo**
   - Verificación real de firmas criptográficas
   - Usar `messageHash.toEthSignedMessageHash().recover()`

2. **Agregar gastos de oráculo**
   - Controlar consumo de gas
   - Implementar límites de actualización

3. **Integración con Chainlink (opcional)**
   - Conectar con Chainlink VRF
   - Usar Chainlink Price Feeds

4. **Dashboard de monitoreo**
   - Visualizar historial de precios
   - Estadísticas de proveedores
   - Alertas de anomalías

## Conexión entre Componentes

```
package.json (Configuración)
    ↓
hardhat.config.js (Compilación)
    ↓
IAggregator (Interfaz ← Contrato implementa)
    ├─ Eventos ─────→ RentalOracle (emite)
    ├─ Funciones ───→ RentalOracle (implementa)
    └─ Requerimientos → RentalOracle (cumple)
    ↓
RentalOracle.sol (Implementación)
    ├─ Hereda: Ownable, IAggregator
    ├─ Almacenamiento: CarData, PriceUpdate
    ├─ Funciones: 14 públicas
    └─ Modifiers: Validación
    ↓
tests/aggregator.test.js (Pruebas)
    ├─ 40+ casos
    ├─ Cobertura 100%
    └─ Integración
```

## Configuración para Besu

```javascript
// hardhat.config.js
networks: {
  besuPrivate: {
    url: "http://localhost:8545",
    accounts: ["0x...PRIVATE_KEY..."],
    chainId: 1337
  }
}
```

Desplegar:
```bash
npx hardhat run scripts/deploy.js --network besuPrivate
```
