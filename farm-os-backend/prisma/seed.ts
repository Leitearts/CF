import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Roles required by FarmMember (needed before any farm can be created)
  await prisma.role.upsert({
    where: { name: 'farmer' },
    update: {},
    create: { name: 'farmer' },
  });
  await prisma.role.upsert({
    where: { name: 'farm_manager' },
    update: {},
    create: { name: 'farm_manager' },
  });
  await prisma.role.upsert({
    where: { name: 'admin' },
    update: {},
    create: { name: 'admin' },
  });

  // System default species + categories (farmId = null).
  // These ship with the platform; farms can add custom categories on top later.
  const speciesSeed: Record<string, string[]> = {
    Pig: ['Boar', 'Sow', 'Gilt', 'Piglet', 'Weaner', 'Grower', 'Finisher'],
    'Dairy Cattle': ['Calf', 'Heifer', 'Milking Cow', 'Dry Cow', 'Bull'],
    Chicken: ['Chick', 'Grower', 'Layer', 'Broiler', 'Cockerel'],
    Dog: ['Puppy', 'Adult', 'Breeding'],
  };

  for (const [speciesName, categories] of Object.entries(speciesSeed)) {
    let species = await prisma.species.findFirst({
      where: { name: speciesName, farmId: null },
    });
    if (!species) {
      species = await prisma.species.create({ data: { name: speciesName } });
    }

    for (const categoryName of categories) {
      const existingCategory = await prisma.animalCategory.findFirst({
        where: { speciesId: species.id, name: categoryName, farmId: null },
      });
      if (!existingCategory) {
        await prisma.animalCategory.create({
          data: { speciesId: species.id, name: categoryName },
        });
      }
    }
  }

  console.log('Seed complete: roles + default species/categories.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
