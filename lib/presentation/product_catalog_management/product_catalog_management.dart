import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/add_product_fab_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/product_list_item_widget.dart';

/// Product Catalog Management Screen
/// Enables business owners to organize and maintain their product inventory
class ProductCatalogManagement extends StatefulWidget {
  const ProductCatalogManagement({super.key});

  @override
  State<ProductCatalogManagement> createState() =>
      _ProductCatalogManagementState();
}

class _ProductCatalogManagementState extends State<ProductCatalogManagement> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;
  bool _isMultiSelectMode = false;
  bool _isGridView = false;
  Set<String> _selectedProducts = {};
  List<Map<String, dynamic>> _filteredProducts = [];
  String _selectedCategory = 'All';

  // Mock product data
  final List<Map<String, dynamic>> _products = [
    {
      "id": "1",
      "name": "Savon Naturel à l'Huile d'Olive",
      "price": "\$12.99",
      "stock": 45,
      "category": "Soap",
      "visibility": true,
      "image":
          "https://images.unsplash.com/photo-1630932022220-807eebd3c4e4",
      "semanticLabel":
          "Natural olive oil soap bar with green packaging on white background",
      "description": "Savon artisanal fabriqué avec de l'huile d'olive pure",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 2)),
    },
    {
      "id": "2",
      "name": "Nettoyant Multi-Surfaces Bio",
      "price": "\$8.50",
      "stock": 120,
      "category": "Cleaning",
      "visibility": true,
      "image":
          "https://images.unsplash.com/photo-1722842253242-1a40ba701095",
      "semanticLabel":
          "Eco-friendly multi-surface cleaner spray bottle with green label",
      "description": "Nettoyant écologique pour toutes surfaces",
      "lastUpdated": DateTime.now().subtract(Duration(days: 1)),
    },
    {
      "id": "3",
      "name": "Gel Douche Hydratant Aloe Vera",
      "price": "\$15.99",
      "stock": 8,
      "category": "Hygiene",
      "visibility": true,
      "image":
          "https://images.unsplash.com/photo-1596099832784-ffd0f966e8b8",
      "semanticLabel":
          "Clear shower gel bottle with aloe vera extract and green cap",
      "description": "Gel douche enrichi à l'aloe vera pour une peau douce",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 5)),
    },
    {
      "id": "4",
      "name": "Crème Anti-Âge Premium",
      "price": "\$45.00",
      "stock": 25,
      "category": "Cosmetics",
      "visibility": false,
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1ff6c0679-1765104987808.png",
      "semanticLabel":
          "Luxury anti-aging cream jar with gold accents on marble surface",
      "description": "Crème anti-âge avec ingrédients naturels premium",
      "lastUpdated": DateTime.now().subtract(Duration(days: 3)),
    },
    {
      "id": "5",
      "name": "Désinfectant Mains Antibactérien",
      "price": "\$6.99",
      "stock": 200,
      "category": "Hygiene",
      "visibility": true,
      "image":
          "https://images.unsplash.com/photo-1716003796312-3d047801272b",
      "semanticLabel":
          "Hand sanitizer bottle with pump dispenser and antibacterial label",
      "description":
          "Gel désinfectant pour les mains, élimine 99.9% des bactéries",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 12)),
    },
    {
      "id": "6",
      "name": "Shampooing Réparateur Argan",
      "price": "\$18.50",
      "stock": 60,
      "category": "Cosmetics",
      "visibility": true,
      "image":
          "https://images.unsplash.com/photo-1600292358763-d704cfbaacdc",
      "semanticLabel":
          "Argan oil shampoo bottle with golden liquid and brown label",
      "description": "Shampooing à l'huile d'argan pour cheveux abîmés",
      "lastUpdated": DateTime.now().subtract(Duration(days: 2)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_products);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filterProducts();
    });
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        bool matchesSearch =
            product["name"].toString().toLowerCase().contains(query) ||
                product["description"].toString().toLowerCase().contains(query);
        bool matchesCategory = _selectedCategory == 'All' ||
            product["category"] == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterProducts();
      }
    });
  }

  void _showFilterBottomSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        selectedCategory: _selectedCategory,
        onCategorySelected: (category) {
          setState(() {
            _selectedCategory = category;
            _filterProducts();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleViewMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _toggleMultiSelectMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedProducts.clear();
      }
    });
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
      } else {
        _selectedProducts.add(productId);
      }
    });
  }

  void _handleBulkDelete() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${_selectedProducts.length} produit(s)?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _products
                    .removeWhere((p) => _selectedProducts.contains(p["id"]));
                _filterProducts();
                _selectedProducts.clear();
                _isMultiSelectMode = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produits supprimés avec succès')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _handleBulkCategoryChange() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer la catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              ['Soap', 'Cleaning', 'Hygiene', 'Cosmetics'].map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  for (var product in _products) {
                    if (_selectedProducts.contains(product["id"])) {
                      product["category"] = category;
                    }
                  }
                  _filterProducts();
                  _selectedProducts.clear();
                  _isMultiSelectMode = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catégorie mise à jour')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleBulkExport() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export en cours...')),
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _filterProducts();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventaire synchronisé')),
      );
    }
  }

  void _navigateToProductDetail(String? productId) {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(
      context,
      '/product-detail-editor',
      arguments: productId,
    );
  }

  void _handleAddProduct() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/product-detail-editor');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              )
            : Text(
                'Produits',
                style: theme.appBarTheme.titleTextStyle,
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _toggleSearch,
              tooltip: 'Fermer la recherche',
            )
          else ...[
            IconButton(
              icon: CustomIconWidget(
                iconName: 'search',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _toggleSearch,
              tooltip: 'Rechercher',
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: _isGridView ? 'view_list' : 'grid_view',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _toggleViewMode,
              tooltip: _isGridView ? 'Vue liste' : 'Vue grille',
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'filter_list',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _showFilterBottomSheet,
              tooltip: 'Filtrer',
            ),
          ],
        ],
      ),
      body: _filteredProducts.isEmpty
          ? EmptyStateWidget(onAddProduct: _handleAddProduct)
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: Column(
                children: [
                  if (_isMultiSelectMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: theme.colorScheme.primaryContainer,
                      child: Row(
                        children: [
                          Text(
                            '${_selectedProducts.length} sélectionné(s)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: CustomIconWidget(
                              iconName: 'delete',
                              color: theme.colorScheme.error,
                              size: 24,
                            ),
                            onPressed: _selectedProducts.isEmpty
                                ? null
                                : _handleBulkDelete,
                            tooltip: 'Supprimer',
                          ),
                          IconButton(
                            icon: CustomIconWidget(
                              iconName: 'category',
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                            onPressed: _selectedProducts.isEmpty
                                ? null
                                : _handleBulkCategoryChange,
                            tooltip: 'Changer catégorie',
                          ),
                          IconButton(
                            icon: CustomIconWidget(
                              iconName: 'file_download',
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                            onPressed: _selectedProducts.isEmpty
                                ? null
                                : _handleBulkExport,
                            tooltip: 'Exporter',
                          ),
                          IconButton(
                            icon: CustomIconWidget(
                              iconName: 'close',
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                            onPressed: _toggleMultiSelectMode,
                            tooltip: 'Annuler',
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _isGridView
                        ? GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ProductListItemWidget(
                                product: product,
                                isGridView: true,
                                isMultiSelectMode: _isMultiSelectMode,
                                isSelected:
                                    _selectedProducts.contains(product["id"]),
                                onTap: () {
                                  if (_isMultiSelectMode) {
                                    _toggleProductSelection(product["id"]);
                                  } else {
                                    _navigateToProductDetail(product["id"]);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isMultiSelectMode) {
                                    _toggleMultiSelectMode();
                                    _toggleProductSelection(product["id"]);
                                  }
                                },
                                onEdit: () =>
                                    _navigateToProductDetail(product["id"]),
                                onDelete: () {
                                  setState(() {
                                    _products.removeWhere(
                                        (p) => p["id"] == product["id"]);
                                    _filterProducts();
                                  });
                                },
                                onVisibilityToggle: () {
                                  setState(() {
                                    product["visibility"] =
                                        !product["visibility"];
                                  });
                                },
                              );
                            },
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredProducts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ProductListItemWidget(
                                product: product,
                                isGridView: false,
                                isMultiSelectMode: _isMultiSelectMode,
                                isSelected:
                                    _selectedProducts.contains(product["id"]),
                                onTap: () {
                                  if (_isMultiSelectMode) {
                                    _toggleProductSelection(product["id"]);
                                  } else {
                                    _navigateToProductDetail(product["id"]);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isMultiSelectMode) {
                                    _toggleMultiSelectMode();
                                    _toggleProductSelection(product["id"]);
                                  }
                                },
                                onEdit: () =>
                                    _navigateToProductDetail(product["id"]),
                                onDelete: () {
                                  setState(() {
                                    _products.removeWhere(
                                        (p) => p["id"] == product["id"]);
                                    _filterProducts();
                                  });
                                },
                                onVisibilityToggle: () {
                                  setState(() {
                                    product["visibility"] =
                                        !product["visibility"];
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: AddProductFabWidget(onPressed: _handleAddProduct),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/product-catalog-management',
        onNavigate: (route) {
          if (route != '/product-catalog-management') {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
