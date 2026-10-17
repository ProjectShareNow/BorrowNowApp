import 'dart:async';
import 'package:flutter/material.dart';
import '../app/app_config.dart';
import '../models/item_model.dart';
import '../services/service_registry.dart';

class ItemProvider extends ChangeNotifier {
  List<ItemModel> _availableItems = [];
  List<ItemModel> _recentItems = [];
  List<ItemModel> _myItems = [];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedAvailability = 'All';
  String _sortBy = 'recent';

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _availableSub;
  StreamSubscription? _recentSub;
  StreamSubscription? _myItemsSub;

  List<ItemModel> get availableItems => _availableItems;
  List<ItemModel> get recentItems => _recentItems;
  List<ItemModel> get myItems => _myItems;

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  String get selectedAvailability => _selectedAvailability;
  String get sortBy => _sortBy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ItemProvider() {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _availableSub = ServiceRegistry.itemService
        .getAvailableItemsStream()
        .listen(
          (items) {
            _availableItems = items;
            notifyListeners();
          },
          onError: (e) {
            AppConfig.log('Available items stream error: $e');
          },
        );

    _recentSub = ServiceRegistry.itemService.getRecentItemsStream().listen(
      (items) {
        _recentItems = items;
        notifyListeners();
      },
      onError: (e) {
        AppConfig.log('Recent items stream error: $e');
      },
    );
  }

  void listenToUserItems(String userId) {
    _myItemsSub?.cancel();
    _myItemsSub = ServiceRegistry.itemService
        .getMyItemsStream(userId)
        .listen(
          (items) {
            _myItems = items;
            notifyListeners();
          },
          onError: (e) {
            AppConfig.log('User items stream error: $e');
          },
        );
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDepartment(String department) {
    _selectedDepartment = department;
    notifyListeners();
  }

  void setAvailability(String availability) {
    _selectedAvailability = availability;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _selectedDepartment = 'All';
    _selectedAvailability = 'All';
    _sortBy = 'recent';
    notifyListeners();
  }

  List<ItemModel> get filteredItems {
    return ServiceRegistry.itemService.filterItems(
      allItems: _availableItems,
      query: _searchQuery,
      category: _selectedCategory,
      department: _selectedDepartment,
      availability: _selectedAvailability,
      sortBy: _sortBy,
    );
  }

  Future<bool> createItem(ItemModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.itemService.createItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(ItemModel item, String currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.itemService.updateItem(
        item: item,
        currentUserId: currentUserId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItemAvailability(
    String itemId,
    String availability,
    String currentUserId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.itemService.updateItemAvailability(
        itemId: itemId,
        availability: availability,
        currentUserId: currentUserId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(
    String itemId,
    String currentUserId, {
    bool isAdmin = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.itemService.deleteItem(
        itemId: itemId,
        currentUserId: currentUserId,
        isAdmin: isAdmin,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _availableSub?.cancel();
    _recentSub?.cancel();
    _myItemsSub?.cancel();
    super.dispose();
  }
}
