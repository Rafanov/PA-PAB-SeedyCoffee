// Fallback data — used when Supabase not configured
import '../models/user_model.dart';
import '../models/menu_model.dart';
import '../models/banner_model.dart';
import '../models/order_model.dart';

class StaticDatabase {
  StaticDatabase._();

  static List<CategoryModel> get seedCategories => [
    CategoryModel(id:'cat-1', name:'Hot Coffee',  sortOrder: 0),
    CategoryModel(id:'cat-2', name:'Cold Coffee', sortOrder: 1),
    CategoryModel(id:'cat-3', name:'Milk Coffee', sortOrder: 2),
    CategoryModel(id:'cat-4', name:'Non Coffee',  sortOrder: 3),
    CategoryModel(id:'cat-5', name:'Snack',       sortOrder: 4),
  ];

  static List<UserModel> get seedUsers => [
    UserModel(id:'u-001', fullName:'Customer SeedyCoffee', role:UserRole.customer,
      phone:'081234567890', email:'customer@breworder.com', createdAt:DateTime(2025,1,1)),
    UserModel(id:'u-002', fullName:'Admin SeedyCoffee', role:UserRole.admin,
      phone:'081111111111', email:'admin@breworder.com', createdAt:DateTime(2025,1,1)),
    UserModel(id:'u-003', fullName:'Kasir Satu', role:UserRole.cashier,
      phone:'082222222222', email:'kasir@breworder.com', createdAt:DateTime(2025,1,1)),
  ];

  static List<MenuModel> get seedMenus => [
    MenuModel(id:'m-001', categoryId:'cat-1', categoryName:'Hot Coffee',
      name:'Espresso', description:'Rich bold espresso with thick crema.',
      price:25000, originalPrice:32000,
      sizeOptions:['Small','Large'], sugarOptions:['Normal','Less','No Sugar']),
    MenuModel(id:'m-002', categoryId:'cat-1', categoryName:'Hot Coffee',
      name:'Cappuccino', description:'Perfect espresso, steamed milk and microfoam.',
      price:32000,
      sizeOptions:['Small','Medium','Large'], sugarOptions:['Normal','Less','No Sugar']),
    MenuModel(id:'m-003', categoryId:'cat-2', categoryName:'Cold Coffee',
      name:'Iced Latte', description:'Fresh espresso over cold milk and ice.',
      price:35000, originalPrice:45000,
      sizeOptions:['Medium','Large'], sugarOptions:['Normal','Less','No Sugar'],
      iceOptions:['Normal Ice','Less Ice','No Ice']),
    MenuModel(id:'m-004', categoryId:'cat-2', categoryName:'Cold Coffee',
      name:'Cold Brew', description:'Slow-brewed 12 hours. Smooth and naturally sweet.',
      price:38000,
      sizeOptions:['Medium','Large'], sugarOptions:['Normal','Less','No Sugar'],
      iceOptions:['Normal Ice','Less Ice','No Ice']),
    MenuModel(id:'m-005', categoryId:'cat-3', categoryName:'Milk Coffee',
      name:'Velvet Cappuccino', description:'Luxurious espresso meets perfectly steamed milk.',
      price:38000, originalPrice:48000,
      sizeOptions:['Small','Medium','Large'], sugarOptions:['Normal','Less','No Sugar'],
      iceOptions:['Hot','Iced']),
    MenuModel(id:'m-006', categoryId:'cat-4', categoryName:'Non Coffee',
      name:'Matcha Latte', description:'Premium ceremonial matcha with oat milk.',
      price:35000,
      sizeOptions:['Small','Medium','Large'], sugarOptions:['Normal','Less','No Sugar'],
      iceOptions:['Hot','Iced']),
    MenuModel(id:'m-007', categoryId:'cat-5', categoryName:'Snack',
      name:'Butter Croissant', description:'Flaky, buttery layers. Fresh every morning.',
      price:22000, originalPrice:28000,
),
    MenuModel(id:'m-008', categoryId:'cat-5', categoryName:'Snack',
      name:'Cheesecake Slice', description:'NY style cheesecake. Dense and creamy.',
      price:28000,
),
  ];

  static List<BannerModel> get seedBanners => [
    BannerModel.local(id:'b-001', title:'Today Only — 70% OFF',
      imagePath:'assets/images/BannerTest.png', gradientIndex:0,
      shareText:'Diskon 70% untuk semua minuman, hari ini saja!'),
    BannerModel.local(id:'b-002', title:'Velvet Cappuccino — Try Now!',
      imageUrl:'', gradientIndex:1,
      shareText:'Menu baru: Velvet Cappuccino yang lembut dan mewah.'),
    BannerModel.local(id:'b-003', title:'Buy 2 Get 1 Free!',
      imageUrl:'', gradientIndex:2,
      shareText:'Buy 2 Get 1 Free untuk semua member!'),
  ];

  static List<OrderModel> get seedOrders => [];
}
