// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAggregator
 * @dev Interface para agregadores de precios descentralizados
 * Permite que múltiples fuentes de datos (oracles) se conecten y reportem datos verificables
 * @notice Implementa estándares de seguridad para oracles en blockchain
 */
interface IAggregator {
    
    /* ========== EVENTOS ========== */
    
    /// @notice Emitido cuando se actualiza el precio de un modelo
    event PriceUpdated(
        string indexed carModel,
        uint256 newPrice,
        address indexed reporter,
        uint256 timestamp
    );
    
    /// @notice Emitido cuando se actualiza la tasa diaria
    event DailyRateUpdated(
        string indexed carModel,
        uint256 newRate,
        address indexed reporter,
        uint256 timestamp
    );
    
    /// @notice Emitido cuando falla la validación de datos
    event DataValidationFailed(
        string indexed carModel,
        address indexed reporter,
        string reason
    );
    
    /* ========== FUNCIONES DE LECTURA ========== */
    
    /// @notice Obtiene el precio actual de un modelo de auto
    /// @param _carModel Nombre del modelo (ej: "Tesla Model 3")
    /// @return El precio en USD (con 8 decimales)
    function getPrice(string memory _carModel) external view returns (uint256);
    
    /// @notice Obtiene la tasa diaria de renta
    /// @param _carModel Nombre del modelo
    /// @return La tasa en USD por día (con 2 decimales)
    function getDailyRate(string memory _carModel) external view returns (uint256);
    
    /// @notice Calcula el costo total de una renta
    /// @param _carModel Modelo del auto
    /// @param _days Número de días
    /// @return Costo total en USD
    function calculateRentalCost(string memory _carModel, uint256 _days) external view returns (uint256);
    
    /// @notice Obtiene el timestamp de la última actualización
    /// @param _carModel Nombre del modelo
    /// @return Timestamp de Unix de la última actualización
    function getLastUpdateTime(string memory _carModel) external view returns (uint256);
    
    /// @notice Obtiene información sobre la fuente de datos
    /// @param _carModel Nombre del modelo
    /// @return sourceAddress Dirección del reporter/oráculo
    /// @return dataCount Número de actualizaciones registradas
    function getDataSource(string memory _carModel) 
        external view 
        returns (address sourceAddress, uint256 dataCount);
    
    /* ========== FUNCIONES DE ACTUALIZACIÓN (SOLO REPORTADORES) ========== */
    
    /// @notice Reporta un nuevo precio (solo para fuentes autorizadas)
    /// @param _carModel Modelo del auto
    /// @param _price Precio en USD con 8 decimales
    /// @param _signature Firma criptográfica para validación
    function reportPrice(
        string memory _carModel,
        uint256 _price,
        bytes calldata _signature
    ) external;
    
    /// @notice Reporta una nueva tasa diaria
    /// @param _carModel Modelo del auto
    /// @param _rate Tasa en USD por día con 2 decimales
    /// @param _signature Firma criptográfica para validación
    function reportDailyRate(
        string memory _carModel,
        uint256 _rate,
        bytes calldata _signature
    ) external;
    
    /* ========== FUNCIONES DE VALIDACIÓN ========== */
    
    /// @notice Valida la integridad de los datos reportados
    /// @param _carModel Modelo del auto
    /// @param _expectedPrice Precio esperado
    /// @param _tolerance Tolerancia de variación en porcentaje (ej: 5 = 5%)
    /// @return bool true si los datos están dentro de la tolerancia
    function validateData(
        string memory _carModel,
        uint256 _expectedPrice,
        uint256 _tolerance
    ) external view returns (bool);
    
    /// @notice Verifica si un reportador está autorizado
    /// @param _reporter Dirección del reportador
    /// @return bool true si está autorizado
    function isAuthorizedReporter(address _reporter) external view returns (bool);
}
