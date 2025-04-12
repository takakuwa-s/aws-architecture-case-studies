import redis
from typing import Any
from boto3.dynamodb.conditions import Key
from model.db_model import BaseTable
from config.logger import get_app_logger


class BaseTableRepository:
    def __init__(self, dynamodb, table_model: BaseTable, redis_client: redis.Redis):
        self.dynamodb = dynamodb
        self.redis_client = redis_client
        self.table_model = table_model
        self.table = self.dynamodb.Table(self.table_model.get_name())
        self.logger = get_app_logger(__name__)

    def batch_write_items(self, items: list[dict]):
        """
        DynamoDBテーブルに複数アイテムを一括で書き込みます。

        Args:
            items (list[dict]): 書き込むアイテムのリスト
        """
        with self.table.batch_writer() as batch:
            for item in items:
                batch.put_item(Item=item)
        self.logger.info(
            f"{len(items)} items written to table {self.table_model.get_name()}, size = {len(items)}"
        )

    def put_item(self, data: dict):
        """
        アイテムを追加します。
        Args:
            data: 追加するデータ
        """
        self.table.put_item(Item=data)
        self.logger.info(
            f"Item added successfully, table name = {self.table_model.get_name()}, data = {data}"
        )

    def update_item(
        self,
        update_expression: str,
        expression_attribute_names: dict,
        expression_attribute_values: dict,
        partition_key_value: Any,
        sort_key_value: Any = None,
    ):
        """
        DynamoDBテーブルの項目を更新する

        Args:
            update_expression (str): 更新式
            expression_attribute_values (dict): 更新式の変数
            expression_attribute_names (dict): 更新式の変数名
            partition_key_value: パーティションキーの値
            sort_key_value: ソートキーの値
        Returns:
            更新後の属性
        """
        key = self.__get_key(partition_key_value, sort_key_value)
        response = self.table.update_item(
            Key=key,
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW",
        )
        self.logger.info(
            f"UpdateItem succeeded, table name = {self.table_model.get_name()}"
        )
        return self.table_model(**response["Attributes"])

    def get_all(self):
        """
        テーブル内の全てのアイテムを取得します。
        Returns:
            全アイテム
        """
        response = self.table.scan()
        items = response.get("Items")
        return [self.table_model(**item) for item in items]

    def scan_items(self, filter_expression: str):
        """
        フィルタ式を使用してテーブル内のアイテムをスキャンします。
        Args:
            filter_expression: フィルタ式
        Returns:
            スキャン結果
        """
        response = self.table.scan(
            FilterExpression=filter_expression,
        )
        items = response.get("Items")

        while "LastEvaluatedKey" in response:
            response = self.table.scan(
                FilterExpression=filter_expression,
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )
            items.extend(response["Items"])
        return [self.table_model(**item) for item in items]

    def query_items(self, partition_key_value: Any):
        """
        パーティションキーの値で検索を行います。
        Args:
            partition_key_value: パーティションキーの値
        Returns:
            検索結果
        """
        response = self.table.query(
            KeyConditionExpression=Key(self.table_model.get_parttion_key()).eq(
                partition_key_value
            )
        )
        items = response["Items"]
        if items is None:
            self.logger.info(
                f"items not found. partition key value = {partition_key_value}, table name = {self.table_model.get_name()}"
            )
            return None
        self.logger.info(
            f"Item found, table name = {self.table_model.get_name()}, item size = {len(items)}"
        )
        return [self.table_model(**item) for item in items]

    def __get_key(self, partition_key_value: Any, sort_key_value: Any = None) -> dict:
        """
        プライマリキー（パーティションキーとソートキー）を取得します。
        Args:
            partition_key_value: パーティションキーの値
            sort_key_value: ソートキーの値
        Returns:
            プライマリキー
        """
        key = {
            self.table_model.get_parttion_key(): partition_key_value,
        }
        if sort_key_value is not None:
            key[self.table_model.get_sort_key()] = sort_key_value
        return key

    def get_item(self, partition_key_value: Any, sort_key_value: Any = None):
        """
        プライマリキー（パーティションキーとソートキー）を使用して単一の項目を取得します。
        Args:
            partition_key_value: パーティションキーの値
            sort_key_value: ソートキーの値
        Returns:
            アイテム
        """
        key = self.__get_key(partition_key_value, sort_key_value)
        response = self.table.get_item(Key=key)
        item = response.get("Item")
        if item is None:
            self.logger.info(
                f"items not found. partition key value = {partition_key_value}, sort key value = {sort_key_value}, table name = {self.table_model.get_name()}"
            )
            return None
        self.logger.info(
            f"Item found, table name = {self.table_model.get_name()}, item = {item}"
        )
        return self.table_model(**item)

    def delete_item(self, partition_key_value: Any, sort_key_value: Any = None):
        """
        指定されたキーを持つ項目をDynamoDBテーブルから削除します。

        Args:
            partition_key_value: パーティションキーの値
            sort_key_value: ソートキーの値
        """
        key = self.__get_key(partition_key_value, sort_key_value)
        self.table.delete_item(Key=key)
        self.logger.info(
            f"Item with key {key} deleted from table {self.table_model.get_name()}."
        )

    def set_cache(self, key: any, value: BaseTable):
        """
        Redisにデータをセットする
        :param key: Redisのキー
        :param value: Redisの値
        """
        key = str(key)
        value = value.model_dump_json()
        self.logger.info(f"Set redis key: {key}, value: {value}")
        # 1時間でExpireするように設定
        self.redis_client.set(key, value, ex=3600)
  
    def get_cache(self, key: any):
        """
        Redisからデータを取得する
        :param key: Redisのキー
        :return: Redisの値
        """
        key = str(key)
        value = self.redis_client.get(key)
        if value is not None:
            value = self.table_model.model_validate_json(value)
        self.logger.info(f"Get redis key: {key}, value: {value}")
        return value