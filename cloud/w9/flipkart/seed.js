const mongoose = require("mongoose");

const User = require("../backend/models/userModel");
const Product = require("../backend/models/productModel");
const Order = require("../backend/models/orderModel");

const MONGO_URI = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/flipkart";

const sampleImage = (text) => ({
  public_id: `sample-${text.toLowerCase().replace(/\s+/g, "-")}`,
  url: `https://dummyimage.com/600x600/ffffff/2874f0&text=${encodeURIComponent(text)}`,
});

const sampleLogo = (brand) => ({
  public_id: `brand-${brand.toLowerCase().replace(/\s+/g, "-")}`,
  url: `https://dummyimage.com/160x40/f5f5f5/111111&text=${encodeURIComponent(brand)}`,
});

async function seed() {
  await mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });

  console.log(`Connected to ${MONGO_URI}`);

  await Order.deleteMany({});
  await Product.deleteMany({});
  await User.deleteMany({});

  const [adminUser, customerUser] = await User.create([
    {
      name: "Admin Demo",
      email: "admin@flipkart.local",
      gender: "male",
      password: "Admin@12345",
      role: "admin",
      avatar: sampleImage("Admin"),
    },
    {
      name: "Customer Demo",
      email: "customer@flipkart.local",
      gender: "female",
      password: "Customer@12345",
      role: "user",
      avatar: sampleImage("Customer"),
    },
  ]);

  const products = await Product.create([
    {
      name: "iPhone 15 128GB",
      description: "Flagship smartphone with bright display and strong camera system.",
      highlights: ["128GB Storage", "48MP Camera", "A16 Bionic"],
      specifications: [
        { title: "Display", description: "6.1-inch Super Retina XDR" },
        { title: "Battery", description: "All-day battery life" },
      ],
      price: 79999,
      cuttedPrice: 89999,
      images: [sampleImage("iPhone 15")],
      brand: {
        name: "Apple",
        logo: sampleLogo("Apple"),
      },
      category: "Mobiles",
      stock: 25,
      warranty: 1,
      ratings: 4.7,
      numOfReviews: 1,
      reviews: [
        {
          user: customerUser._id,
          name: customerUser.name,
          rating: 5,
          comment: "Smooth performance and premium feel.",
        },
      ],
      user: adminUser._id,
    },
    {
      name: "Samsung Galaxy S24",
      description: "Android flagship with vivid AMOLED panel and versatile cameras.",
      highlights: ["256GB Storage", "AMOLED Display", "Fast Charging"],
      specifications: [
        { title: "Display", description: "6.2-inch Dynamic AMOLED" },
        { title: "Processor", description: "Snapdragon flagship chipset" },
      ],
      price: 68999,
      cuttedPrice: 75999,
      images: [sampleImage("Galaxy S24")],
      brand: {
        name: "Samsung",
        logo: sampleLogo("Samsung"),
      },
      category: "Mobiles",
      stock: 18,
      warranty: 1,
      ratings: 4.5,
      numOfReviews: 1,
      reviews: [
        {
          user: customerUser._id,
          name: customerUser.name,
          rating: 4,
          comment: "Great screen and battery for daily use.",
        },
      ],
      user: adminUser._id,
    },
    {
      name: "ASUS ROG Strix G16",
      description: "Gaming laptop for development, streaming and AAA titles.",
      highlights: ["16GB RAM", "RTX Graphics", "165Hz Display"],
      specifications: [
        { title: "CPU", description: "Intel Core i7" },
        { title: "Storage", description: "1TB NVMe SSD" },
      ],
      price: 124990,
      cuttedPrice: 139990,
      images: [sampleImage("ROG Strix G16")],
      brand: {
        name: "ASUS",
        logo: sampleLogo("ASUS"),
      },
      category: "Laptops",
      stock: 10,
      warranty: 2,
      ratings: 4.6,
      numOfReviews: 1,
      reviews: [
        {
          user: customerUser._id,
          name: customerUser.name,
          rating: 5,
          comment: "Runs fast and handles heavy workloads well.",
        },
      ],
      user: adminUser._id,
    },
    {
      name: "Sony WH-1000XM5",
      description: "Wireless noise-cancelling headphones for work and travel.",
      highlights: ["ANC", "30 Hours Battery", "Multipoint Bluetooth"],
      specifications: [
        { title: "Connectivity", description: "Bluetooth 5.x" },
        { title: "Weight", description: "Approx 250g" },
      ],
      price: 24999,
      cuttedPrice: 29999,
      images: [sampleImage("Sony XM5")],
      brand: {
        name: "Sony",
        logo: sampleLogo("Sony"),
      },
      category: "Audio",
      stock: 35,
      warranty: 1,
      ratings: 4.4,
      numOfReviews: 1,
      reviews: [
        {
          user: customerUser._id,
          name: customerUser.name,
          rating: 4,
          comment: "Comfortable and blocks noise nicely.",
        },
      ],
      user: adminUser._id,
    },
  ]);

  await Order.create({
    shippingInfo: {
      address: "123 Demo Street",
      city: "Da Nang",
      state: "Hai Chau",
      country: "Vietnam",
      pincode: 550000,
      phoneNo: 912345678,
    },
    orderItems: [
      {
        name: products[0].name,
        price: products[0].price,
        quantity: 1,
        image: products[0].images[0].url,
        product: products[0]._id,
      },
      {
        name: products[3].name,
        price: products[3].price,
        quantity: 1,
        image: products[3].images[0].url,
        product: products[3]._id,
      },
    ],
    user: customerUser._id,
    paymentInfo: {
      id: "txn-demo-0001",
      status: "succeeded",
    },
    paidAt: new Date(),
    totalPrice: products[0].price + products[3].price,
    orderStatus: "Processing",
  });

  console.log("Seed completed");
  console.log("Admin login: admin@flipkart.local / Admin@12345");
  console.log("Customer login: customer@flipkart.local / Customer@12345");
}

seed()
  .catch((error) => {
    console.error("Seed failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.connection.close();
  });
