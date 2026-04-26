//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IAggregator.sol";

/**
* @title RentalOracle
* @dev Oráculo descentralizado para precios de rentas de autos en red privada Besu
* Implementa verificación con fimras criptográficas, auditoría completa y validación de datos
* @notice Conecta con múltiples fuentes de datos autorizadas y valida su integridad
*/
contract RentaOracule is Ownable, IAggregator {

  using ECDSA for bytes32;

  // ============== ESTRUCTURAS ==========

  /// @DEV Estructura para almacenar precios de autos
  struct CarData {
  string model;              // Modelo del auto (Tesla Model 3)
  uint256 price;             // Precio en USD (8 decimales)
  uint256 dailyRate;         // Tasa diaria en USD (2 decimales)
  uint256 lastUpdated;       // Timestamp de ultima actualización
  address dataProvider;      // Quién proporcionó los datos
  bool isActive;             // Si está activo
  uint256 updateCount;       // Número de actualizaciones
}

/// @dev Estructura para auditoría detallada
struct PriceUpdate {
string carModel;
uint256 oldPrice;
uint256 nrePrice;
uint256 timestamp;
address updatedBy;
bool isValid;         // Si pasó validación
}

// ======= MAPPING ===========

/// @dev Mapeo de modelos de autos a sus datos
mapping(string => CarData) public carDatabase;

/// @dev Proveedores autorizados de autos
mapping(address => bool) public authorizedProviders;

/// @dev Histórico de actualizaciones para auditoría
PriceUpdate[] public priceHistory;

/// @dev Lista de modelos disponibles
string[] public availableModels;

/// @devTolerancia por defecto para validación (en %)
uint256 public defaultTolerance = 10;

// ================= EVENTOS (Implementados de IAggregator) =======

// ya definidos en IAggregator, pero recopilados aqui para claridad
// event PriceUpdated(string indexed CarModel, uint256 newPrice, address reporter, uint256 timestamp);
// event DailyRateUpdated(string indexed carModel, uint256 newRate, address indexed reporter, uint256 timestamp);
// event DataValidationFailed(string indexed carModel, address indexed reporter, string reason);

event ProviderAuthorized(address indexed provider);
event ProviderRevoked(address indexed provider);
event ToleranceUpdated(uint256 newTolerance);

// ========== MODIFIERS ========

modifier onlyAuthorizedProvider() {
     require(authorizedProviders[msg.sender], "No autorizado como proveedor");
     _;
}

modifier validCarModel(string memory _model) {
     require(bytes(_model).length > "Modelo inválido");
     _;
}

modifier validPrice(uint256 _price) {
     require(_price > 0, "Precio debe ser mayor a 0");
     _;
}















