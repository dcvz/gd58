extends RefCounted
class_name SellerPricing

## Pricing system for sellers asking prices for souls

## Calculate what a seller will ask for a soul
## Sellers add up all qualities (known and unknown) and set price at 75-105% of valuation
static func calculate_asking_price(soul: SoulData, seller_knowledge: DiscoveryLog) -> int:
	# Calculate base value from seller's perspective
	var base_value = QualityValuation.calculate_soul_base_value(soul, seller_knowledge)

	# Seller asks for 75-105% of their calculated value
	var markup_percent = randf_range(0.75, 1.05)
	var asking_price = int(base_value * markup_percent)

	return max(1, asking_price)  # Ensure at least 1 KP
