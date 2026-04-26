const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RentalOracle - Implementación de IAggregator", function () {
  let rentalOracle;
  let owner;
  let reporter;
  let otherAccount;
  
  const MODEL_TESLA = "Tesla Model 3";
  const PRICE_50K = ethers.parseUnits("50000", 8);  // 8 decimales
  const DAILY_RATE_150 = ethers.parseUnits("150", 2); // 2 decimales
  const DAYS = 5n;

  beforeEach(async function () {
    [owner, reporter, otherAccount] = await ethers.getSigners();
    
    // Desplegar contrato
    const RentalOracle = await ethers.getContractFactory("RentalOracle");
    rentalOracle = await RentalOracle.deploy();
    
    // Autorizar reporter
    await rentalOracle.authorizeProvider(reporter.address);
  });

  describe("Despliegue e Inicialización", function () {
    it("Should deploy correctly", async function () {
      expect(rentalOracle.address).to.exist;
    });

    it("Owner debe ser autorizado al desplegar", async function () {
      const isAuthorized = await rentalOracle.isAuthorizedReporter(owner.address);
      expect(isAuthorized).to.be.true;
    });

    it("Default tolerance debe ser 10%", async function () {
      const tolerance = await rentalOracle.defaultTolerance();
      expect(tolerance).to.equal(10);
    });
  });

  describe("Gestión de Proveedores", function () {
    it("Owner puede autorizar proveedores", async function () {
      const isAuthorized = await rentalOracle.isAuthorizedReporter(reporter.address);
      expect(isAuthorized).to.be.true;
    });

    it("Owner puede revocar proveedores", async function () {
      await rentalOracle.revokeProvider(reporter.address);
      const isAuthorized = await rentalOracle.isAuthorizedReporter(reporter.address);
      expect(isAuthorized).to.be.false;
    });

    it("Solo Owner puede autorizar", async function () {
      await expect(
        rentalOracle.connect(reporter).authorizeProvider(otherAccount.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("No acepta dirección nula", async function () {
      await expect(
        rentalOracle.authorizeProvider(ethers.ZeroAddress)
      ).to.be.revertedWith("Dirección inválida");
    });
  });

  describe("reportPrice - Función IAggregator", function () {
    it("Reporter autorizado puede reportar precio", async function () {
      // Usar firma vacía por ahora (implementar ECDSA en producción)
      await expect(
        rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x")
      ).to.emit(rentalOracle, "PriceUpdated");
    });

    it("Debe rechazar modelo vacío", async function () {
      await expect(
        rentalOracle.connect(reporter).reportPrice("", PRICE_50K, "0x")
      ).to.be.revertedWith("Modelo inválido");
    });

    it("Debe rechazar precio cero", async function () {
      await expect(
        rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, 0, "0x")
      ).to.be.revertedWith("Precio debe ser mayor a 0");
    });

    it("Reporter no autorizado es rechazado", async function () {
      await expect(
        rentalOracle.connect(otherAccount).reportPrice(MODEL_TESLA, PRICE_50K, "0x")
      ).to.be.revertedWith("Proveedor no autorizado");
    });

    it("Actualiza correctamente el precio", async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      const price = await rentalOracle.getPrice(MODEL_TESLA);
      expect(price).to.equal(PRICE_50K);
    });
  });

  describe("reportDailyRate - Función IAggregator", function () {
    it("Reporter autorizado puede reportar tasa diaria", async function () {
      await expect(
        rentalOracle.connect(reporter).reportDailyRate(MODEL_TESLA, DAILY_RATE_150, "0x")
      ).to.emit(rentalOracle, "DailyRateUpdated");
    });

    it("Actualiza correctamente la tasa", async function () {
      await rentalOracle.connect(reporter).reportDailyRate(MODEL_TESLA, DAILY_RATE_150, "0x");
      const rate = await rentalOracle.getDailyRate(MODEL_TESLA);
      expect(rate).to.equal(DAILY_RATE_150);
    });
  });

  describe("getPrice - Función IAggregator", function () {
    beforeEach(async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
    });

    it("Retorna precio reportado", async function () {
      const price = await rentalOracle.getPrice(MODEL_TESLA);
      expect(price).to.equal(PRICE_50K);
    });

    it("Rechaza modelo no activo", async function () {
      await expect(
        rentalOracle.getPrice("Modelo Inexistente")
      ).to.be.revertedWith("Modelo no activo");
    });
  });

  describe("getDailyRate - Función IAggregator", function () {
    beforeEach(async function () {
      await rentalOracle.connect(reporter).reportDailyRate(MODEL_TESLA, DAILY_RATE_150, "0x");
    });

    it("Retorna tasa diaria reportada", async function () {
      const rate = await rentalOracle.getDailyRate(MODEL_TESLA);
      expect(rate).to.equal(DAILY_RATE_150);
    });
  });

  describe("calculateRentalCost - Función IAggregator", function () {
    beforeEach(async function () {
      await rentalOracle.connect(reporter).reportDailyRate(MODEL_TESLA, DAILY_RATE_150, "0x");
    });

    it("Calcula costo correctamente", async function () {
      const cost = await rentalOracle.calculateRentalCost(MODEL_TESLA, DAYS);
      const expected = DAILY_RATE_150 * DAYS;
      expect(cost).to.equal(expected);
    });

    it("Rechaza días cero", async function () {
      await expect(
        rentalOracle.calculateRentalCost(MODEL_TESLA, 0)
      ).to.be.revertedWith("Días debe ser mayor a 0");
    });
  });

  describe("getLastUpdateTime - Función IAggregator", function () {
    it("Retorna timestamp de actualización", async function () {
      const txReceipt = await rentalOracle
        .connect(reporter)
        .reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      
      const timestamp = await rentalOracle.getLastUpdateTime(MODEL_TESLA);
      expect(timestamp).to.be.greaterThan(0);
    });
  });

  describe("getDataSource - Función IAggregator", function () {
    it("Retorna información de origen de datos", async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      
      const [source, updateCount] = await rentalOracle.getDataSource(MODEL_TESLA);
      expect(source).to.equal(reporter.address);
      expect(updateCount).to.equal(1);
    });

    it("Incrementa contador con múltiples actualizaciones", async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K * 2n, "0x");
      
      const [, updateCount] = await rentalOracle.getDataSource(MODEL_TESLA);
      expect(updateCount).to.equal(2);
    });
  });

  describe("validateData - Función IAggregator", function () {
    beforeEach(async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
    });

    it("Valida datos dentro de tolerancia", async function () {
      const isValid = await rentalOracle.validateData(MODEL_TESLA, PRICE_50K, 5);
      expect(isValid).to.be.true;
    });

    it("Rechaza datos fuera de tolerancia", async function () {
      // Precio esperado muy diferente
      const isValid = await rentalOracle.validateData(
        MODEL_TESLA, 
        PRICE_50K + ethers.parseUnits("20000", 8), // 40% de diferencia
        5 // 5% tolerancia
      );
      expect(isValid).to.be.false;
    });

    it("Rechaza tolerancia inválida", async function () {
      await expect(
        rentalOracle.validateData(MODEL_TESLA, PRICE_50K, 0)
      ).to.be.revertedWith("Tolerancia inválida");
    });
  });

  describe("isAuthorizedReporter - Función IAggregator", function () {
    it("Retorna true para proveedores autorizados", async function () {
      const isAuthorized = await rentalOracle.isAuthorizedReporter(reporter.address);
      expect(isAuthorized).to.be.true;
    });

    it("Retorna false para no autorizados", async function () {
      const isAuthorized = await rentalOracle.isAuthorizedReporter(otherAccount.address);
      expect(isAuthorized).to.be.false;
    });
  });

  describe("Auditoría y Trazabilidad", function () {
    it("Registra historial de actualizaciones", async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      
      const history = await rentalOracle.getPriceHistory();
      expect(history.length).to.equal(1);
      expect(history[0].carModel).to.equal(MODEL_TESLA);
    });

    it("Mantiene lista de modelos disponibles", async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      
      const models = await rentalOracle.getAvailableModels();
      expect(models).to.include(MODEL_TESLA);
    });

    it("getCarData retorna estructura completa", async function () {
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      
      const carData = await rentalOracle.getCarData(MODEL_TESLA);
      expect(carData.model).to.equal(MODEL_TESLA);
      expect(carData.price).to.equal(PRICE_50K);
      expect(carData.isActive).to.be.true;
    });
  });

  describe("Configuración de Tolerancia", function () {
    it("Owner puede cambiar tolerancia por defecto", async function () {
      await rentalOracle.setDefaultTolerance(20);
      const tolerance = await rentalOracle.defaultTolerance();
      expect(tolerance).to.equal(20);
    });

    it("Emite evento al actualizar tolerancia", async function () {
      await expect(
        rentalOracle.setDefaultTolerance(15)
      ).to.emit(rentalOracle, "ToleranceUpdated");
    });

    it("Rechaza tolerancia inválida", async function () {
      await expect(
        rentalOracle.setDefaultTolerance(0)
      ).to.be.revertedWith("Tolerancia inválida");

      await expect(
        rentalOracle.setDefaultTolerance(101)
      ).to.be.revertedWith("Tolerancia inválida");
    });
  });

  describe("Integración Completa", function () {
    it("Workflow completo: reportar → validar → calcular", async function () {
      // 1. Reportar precio y tasa
      await rentalOracle.connect(reporter).reportPrice(MODEL_TESLA, PRICE_50K, "0x");
      await rentalOracle.connect(reporter).reportDailyRate(MODEL_TESLA, DAILY_RATE_150, "0x");
      
      // 2. Validar datos
      const isValid = await rentalOracle.validateData(MODEL_TESLA, PRICE_50K, 10);
      expect(isValid).to.be.true;
      
      // 3. Obtener información
      const price = await rentalOracle.getPrice(MODEL_TESLA);
      const rate = await rentalOracle.getDailyRate(MODEL_TESLA);
      const [source, updateCount] = await rentalOracle.getDataSource(MODEL_TESLA);
      
      expect(price).to.equal(PRICE_50K);
      expect(rate).to.equal(DAILY_RATE_150);
      expect(source).to.equal(reporter.address);
      
      // 4. Calcular costo
      const cost = await rentalOracle.calculateRentalCost(MODEL_TESLA, DAYS);
      expect(cost).to.equal(DAILY_RATE_150 * DAYS);
    });
  });
});
