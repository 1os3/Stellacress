class_name Gamete
extends RefCounted

var chromosomes: Array[Haplotype] = []

func haplotype_for(chromosome_id: int) -> Haplotype:
	for haplotype: Haplotype in chromosomes:
		if haplotype.chromosome_id == chromosome_id:
			return haplotype
	return null
