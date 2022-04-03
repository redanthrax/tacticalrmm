# Generated by Django 3.2.1 on 2021-05-11 02:33

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0018_auto_20210511_0233"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="role",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="roles",
                to="accounts.role",
            ),
        ),
    ]