"""add_soil_depletion_state_table
 
Revision ID: d4e1f2a3b4c5
Revises: 5c9795318a6d
Create Date: 2026-09-09 10:05:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4e1f2a3b4c5'
down_revision: Union[str, Sequence[str], None] = '5c9795318a6d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema: Create soil_depletion_state table."""
    op.create_table(
        'soil_depletion_state',
        sa.Column('farm_plot_id', sa.Integer(), nullable=False),
        sa.Column('current_depletion_mm', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('yesterday_depletion_mm', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('last_updated_date', sa.Date(), nullable=False),
        sa.Column('skipped_runs_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('last_rain_hold_date', sa.Date(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['farm_plot_id'], ['farm_plots.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('farm_plot_id')
    )
    op.create_index(op.f('ix_soil_depletion_state_farm_plot_id'), 'soil_depletion_state', ['farm_plot_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema: Drop soil_depletion_state table."""
    op.drop_index(op.f('ix_soil_depletion_state_farm_plot_id'), table_name='soil_depletion_state')
    op.drop_table('soil_depletion_state')
