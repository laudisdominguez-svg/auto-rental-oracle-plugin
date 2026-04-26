// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  console.log("🚀 Iniciando despliegue de RentalOracle...\n");

  // Obtener cuenta del deployer
  const [deployer] = await ethers.getSigners();
  console.log(`📍 Desplegando desde: ${deployer.address}\n`);

  // Desplegar contrato
  console.log("📦 Compilando RentalOracle...");
  const RentalOracle = await hre.ethers.getContractFactory("RentalOracle");
  
  console.log("⛓️  Desplegando en blockchain...");
  const rentalOracle = await RentalOracle.deploy();
  await rentalOracle.deployed();

  console.log(`✅ RentalOracle desplegado en: ${rentalOracle.address}\n`);

  // Verificar configuración
  console.log("🔍 Verificando configuración inicial...");
  const isOwnerAuthorized = await rentalOracle.isAuthorizedReporter(deployer.address);
  const defaultTolerance = await rentalOracle.defaultTolerance();
  
  console.log(`   Owner autorizado: ${isOwnerAuthorized ? "✅" : "❌"}`);
  console.log(`   Tolerancia por defecto: ${defaultTolerance}%\n`);

  // Datos de ejemplo
  const exampleCars = [
    { model: "Tesla Model 3", price: "50000", dailyRate: "150" },
    { model: "BMW i7", price: "120000", dailyRate: "350" },
    { model: "Audi Q4 e-tron", price: "80000", dailyRate: "250" },
  ];

  console.log("📝 Agregando autos de ejemplo...");
  for (const car of exampleCars) {
    const priceWithDecimals = hre.ethers.parseUnits(car.price, 8);
    const rateWithDecimals = hre.ethers.parseUnits(car.dailyRate, 2);

    try {
      const tx = await rentalOracle.reportPrice(car.model, priceWithDecimals, "0x");
      await tx.wait();
      
      const tx2 = await rentalOracle.reportDailyRate(car.model, rateWithDecimals, "0x");
      await tx2.wait();
      
      console.log(`   ✅ ${car.model}`);
    } catch (error) {
      console.log(`   ❌ Error desplegando ${car.model}: ${error.message}`);
    }
  }

  // Obtener información
  console.log("\n📊 Información de autos registrados:\n");
  const models = await rentalOracle.getAvailableModels();
  
  for (const model of models) {
    try {
      const price = await rentalOracle.getPrice(model);
      const dailyRate = await rentalOracle.getDailyRate(model);
      const [source, updateCount] = await rentalOracle.getDataSource(model);
      
      console.log(`${model}`);
      console.log(`   Precio: $${hre.ethers.formatUnits(price, 8)}`);
      console.log(`   Tasa diaria: $${hre.ethers.formatUnits(dailyRate, 2)}`);
      console.log(`   Actualizaciones: ${updateCount}`);
      console.log(`   Proveedor: ${source}\n`);
    } catch (error) {
      console.log(`   Error leyendo ${model}: ${error.message}\n`);
    }
  }

  // Guardar información de despliegue
  const deploymentInfo = {
    contractAddress: rentalOracle.address,
    deployer: deployer.address,
    deployedAt: new Date().toISOString(),
    network: hre.network.name,
    cars: models
  };

  const fs = require("fs");
  fs.writeFileSync(
    "./deployment-info.json",
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("✨ Despliegue completado exitosamente!");
  console.log(`\n📌 Información guardada en: deployment-info.json\n`);

  return rentalOracle.address;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
