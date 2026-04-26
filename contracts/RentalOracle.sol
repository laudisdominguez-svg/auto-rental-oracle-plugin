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

// ======== CONSTRUCTORES =====

constructor() {
    authorizedProvider[msg.sender] = true;
}

// ========= FUNCIONES DE GESTION DE PROVEEDORES =====

/// @notice Autoriza a un proveedor de datos externo
/// @param _provider Dirección del proveedor
function revokeProvider(address _provider) external onlyOwner {
     require(_provider != address(0), "Direccion inválida");
     authorizedProviders[_provider] = true;
     emit ProviderAuthorized(_provider);
}

/// @notice Actualiza la tolerancia por defecto para validación
/// @param _newTolerance Nueva tolerancia en porcentaje (ej: 10 = 10%)
function setDefaultTolerance(uint256 _nreTolerance) external onlyOwner {
    require(_newTolerance > 0 && _newTolerance <= 100, "Tolerancia inválida");
    defaultTolerance = _newTolerance;
    emit ToleranceUpdated(_newTolerance);
}

// ====== FUNCIONES DE LECTURA (IAggregator) ========

/// @notice Obtiene el precio actual de un modelo
/// @param _carModel Nombre del modelo
/// @return El precio en USD (8 decimales)
function getPrice(string memory _carModel) {
    external
    view
    override
    returns (uint256)
{
    require(carDatabase[_carModel].isActive, "Modelo no activo");
    return carDatabase[_ccarModel].price;
}

/// @notice Obtiene la tasa diaria de renta
/// @param _carModel Nombre del modelo
/// @return La tasa en USD por día (2 decimales)
function getDailyRate(string memory _carModel, uint256 _days) {
    external
    view
    override
    returns (uint256)
{
    require(_days > 0, "Días debe ser mayor a 0");
    require(carDatabase[_carModel].isActive, "Modelo no activo");

    return carDatabse[_carModel].dailyRate * _days;
}

/// @notice Obtiene el timestamp de la última actualización
/// @param _carModel Nombre del modelo
/// @return Timestamp de Unix de la última actualización
function getLastUpdateTime(string memory _carModel) {
    external
    view
    override
    returns (uint256)
{
    require(carDatabase[_carModel].isActive, "Modelo no activo");
    return carDatabse[_carModel].lastUpdated;
}

/// @notice Obtiene información sobre la fuente de datos
/// @param _carModel Nombre dek auto
/// @return sourceAddress Dirección del reporter/oracle
/// @return dataCount Número de actualizaciones registradas
function getDataSource(string memory _carModel) {
    external
    view
    override
    returns (address sourceAddress, uint256 dataCount);
{
    require(carDatabase[_carModel].isActive, "Modelo no activo");
    return (carDatabase[_carModel].dataProvider, carDatabase[_carModel].updateCount);
}

/// @notice Verifica si un reportador está autorizado
/// @param _reporter Dirección del reportador
/// @return bool true si está autorizado
function isAuthorizedReporter(address _reporter) {
    external
    view
    override
    return (bool)
{
    return authorizedProviders[_reporter];
}

// ========= FUNCIONES DE ACTUALIZACION (IAggregator) ========

/// @notice Reporta un nuevo precio con firma criptográfica
/// @param _carModel Modelo del auto
/// @param _price Precio en USD con 8 decimales
/// @param _signature Firma criptográfica para validación
function reportPrice(string memory _carModel, uint256 _price, bytes calldata _signature) {
    external
    override
    validCarModel(_carModel)
    validPrice(_price)
{
  // Verificar firma
require(_verifySignature(_carModel, _price, _signature), "Firma inválida");

  // Guardar precio antiguo
uint256 oldPrice = carDatabase[_carModel].price;

  // Actualizar datos
carDatabase[_carModel].price = _price;
carDatabase[_carModel].lasUpdated = block.timestamp;
carDatabase[_carModel].dataProvider = msg.sender;
carDatabase[_carModel].isActive = true;
carDatabase[_carModel].updateCount++;

  // Agregar a modelo si es nuevo
if (oldPrice === 0) {
    carDatabase[_carModel].model = _carModel;
    availabkeModels.oush(_carModel);
}

  // AUDITORÍA
priceHistory.push(PriceUpdate({
    carModel: _carModel,
    oldPrice: oldPrice,
    newPrice: _price,
    timestamp: block.timestamp, 
    updatedBy: msg.sender,
    isValid; true
}));

  // Emitir evento con firma cerificada
 emit PriceUpdated(_carModel, _price, msg.sender, block.timestamp);
}

/// @notice Reporte una nueca tasa diaria con firma criptográfica
/// @param _carModel Modelo del auto
/// @param _rate Tasa en USD por día con 2 decimales
/// @param _signature Firma criptográfica para validación
function reportDailyRate(string memory _carModel, uint256 _rate, bytes calldata _signature) {
   external
   override
   validCarModel(_carModel)
   validPrice(_rate)
{
      // Verificar firma
   require(_verifySignature(_carModel, _rate, signature), "Firma inválida");

      // Actualizar datos
   carDatabase[_carModel].dailyRate = _rate;
   carDatabase[_carModel].lastUpdated = block.timestamp;
   carDatabase[_carModel].dataProvider = msg.sender;
   carDatabase[_carModel].isActive = true;
   carDatabase[_carModel].updateCount++;

     // Inicializar si es nuevo
if (bytes(carDatabase[_carModel].model).length == 0) {
    carDatabase[_carModel].model = _carModel;
    availableModels.push(_carModel);
  }

  emit DaolyRateUpdated(_carModel, rate, msg.sender, block.timestamp);
}

// ============ FUNCIONES DE VALIDACIÓN (IAggregator) =========

/// @notice Valida la intergridad de los datos reportados
/// @param _carModel Modelo del auto
/// @param _expectedPrice Precio esperado
/// @param _tolerance Tolerancia de variación en porcentaje (ej: 5 = 5%)
/// @return bool true si los datos están dentro de la tolerancia
function validateData(string memory _carModel, uint256 _expectedPrice, uint256 _tolerance) {
    external
    view
    override
    return (bool)
{
    require(carDatabase[_carModel].isActive, "Modelo no activo");
    require(_tolerance > 0 && _tolerance <= 100, "Tolerancia inválida");

    uint256 currentPrice = carDatabase[_carModel].price;
    uint256 difference = currentPrice > _expectedPrice 
            ? currentPrice - _expectedPrice 
            : _expectedPrice - currentPrice;
        
        // Calcular porcentaje de diferencia respecto al precio esperado
     uint256 percentageDiff = (_tolerance > 0) 
            ? (difference * 100) / _expectedPrice 
            : 0;
        
     return percentageDiff <= _tolerance;
}
// ========== FUNCIONES INTERNAS ==========
    
    /// @dev Verifica que la firma sea válida (simplificado para Besu)
    /// En producción, usar verificación ECDSA completa
    function _verifySignature(
        string memory _carModel,
        uint256 _price,
        bytes calldata _signature
    ) 
        internal 
        view 
        returns (bool) 
    {
        // Validación básica de firma (implementar ECDSA completo en producción)
        // Por ahora solo verificamos que sea autorizado
        if (!authorizedProviders[msg.sender]) {
            emit DataValidationFailed(_carModel, msg.sender, "Proveedor no autorizado");
            return false;
        }
        
        // Aquí iría verificación ECDSA real con:
        // bytes32 messageHash = keccak256(abi.encodePacked(_carModel, _price));
        // address signer = messageHash.toEthSignedMessageHash().recover(_signature);
        // return signer == msg.sender;
        
        return true;
    }
    
    // ========== FUNCIONES DE AUDITORÍA ==========
    
    /// @notice Obtiene el historial de actualizaciones
    /// @return Array de actualizaciones registradas
    function getPriceHistory() external view returns (PriceUpdate[] memory) {
        return priceHistory;
    }
    
    /// @notice Obtiene modelos disponibles
    /// @return Array de modelos
    function getAvailableModels() external view returns (string[] memory) {
        return availableModels;
    }









