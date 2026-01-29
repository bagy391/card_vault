import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import '../widgets/vertical_card_stack.dart';
import 'add_edit_card_screen.dart';
import '../utils/card_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CardProvider>(context, listen: false).loadCards();
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => const ReorderCardsSheet(),
              );
            },
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No cards added yet'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEditCardScreen(),
                          ),
                        );
                      }
                    },
                    child: const Text('Add your first card'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              VerticalCardStack(
                cards: provider.cards,
                onCardTap: (card) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditCardScreen(card: card),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '${provider.cards.length} Cards in Wallet',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditCardScreen(),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReorderCardsSheet extends StatelessWidget {
  const ReorderCardsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Reorder Cards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Consumer<CardProvider>(
              builder: (context, provider, child) {
                return ReorderableListView.builder(
                  itemCount: provider.cards.length,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderCards(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final card = provider.cards[index];
                    return ListTile(
                      key: ValueKey(card.id),
                      leading:  Padding(padding: EdgeInsets.only(left: 10), child: CardUtils.getCardIcon(CardUtils.getCardTypeFromNumber(card.cardNumber))),
                      title: Text(card.bankName),
                      subtitle: Text('**** ${card.cardNumber.length > 4 ? card.cardNumber.substring(card.cardNumber.length - 4) : card.cardNumber}'),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
