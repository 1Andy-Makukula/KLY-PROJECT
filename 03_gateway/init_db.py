import asyncio
from services.database import engine, Base
from services.models import Transaction

async def init_db():
    async with engine.begin() as conn:
        print("Dropping and recreating global_gifts...")
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
        print("Done!")

if __name__ == "__main__":
    asyncio.run(init_db())
