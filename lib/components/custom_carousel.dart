import 'package:flutter/material.dart';

class CustomCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final double viewportFraction;

  const CustomCarousel({
    super.key,
    required this.items,
    this.height = 250.0,
    this.viewportFraction = 1.0, // Set to < 1.0 to peek at the next/prev slides
  });

  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
    
    // Listen to scroll changes to update arrow disabled states
    _controller.addListener(() {
      if (_controller.page != null) {
        int next = _controller.page!.round();
        if (_currentPage != next) {
          setState(() {
            _currentPage = next;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.items.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The scrollable area
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // gap between slides
                child: widget.items[index],
              );
            },
          ),
          
          // Floating Previous Button
          Positioned(
            left: 12,
            child: _buildNavButton(
              icon: Icons.arrow_back,
              onTap: _prevPage,
              isDisabled: _currentPage == 0,
            ),
          ),
          
          // Floating Next Button
          Positioned(
            right: 12,
            child: _buildNavButton(
              icon: Icons.arrow_forward,
              onTap: _nextPage,
              isDisabled: _currentPage == widget.items.length - 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDisabled,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.0 : 1.0, // Hides button if it can't be clicked
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(20), // size-8 rounded-full
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.9), // Muted dark background
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}