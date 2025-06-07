import datetime
import uuid
from bson import ObjectId
from ...utils.type_parsers import parse_mongo_doc

class ShareInvitation:
    """行程分享邀请模型
    
    代表对用户行程的邀请，允许其他用户加入并编辑行程。
    """
    
    COLLECTION = 'shareInvitations'
    
    @staticmethod
    def create_invitation(mongo, invitation_data):
        """创建新的行程分享邀请"""
        # 使用UTC时间
        now = datetime.datetime.now(datetime.timezone.utc)
        
        # 确保必填字段存在
        required_fields = ['trip_id', 'sender_user_id', 'sender_name']
        for field in required_fields:
            if field not in invitation_data:
                raise ValueError(f"缺少必要字段: {field}")
        
        # 格式化数据
        if 'trip_id' in invitation_data and isinstance(invitation_data['trip_id'], str):
            try:
                invitation_data['trip_id'] = ObjectId(invitation_data['trip_id'])
            except Exception as e:
                print(f"转换trip_id为ObjectId失败: {e}")
                pass
                
        # 设置默认值
        invitation_data['created_at'] = now
        
        # 处理expires_at字段
        if 'expires_at' not in invitation_data:
            # 默认7天后过期
            invitation_data['expires_at'] = now + datetime.timedelta(days=7)
        else:
            # 如果是字符串，尝试转换为datetime对象
            if isinstance(invitation_data['expires_at'], str):
                try:
                    # 解析日期时间字符串并确保它有时区信息
                    expires_at = datetime.datetime.fromisoformat(
                        invitation_data['expires_at'].replace('Z', '+00:00')
                    )
                    # 确保使用UTC时区
                    if expires_at.tzinfo is None:
                        expires_at = expires_at.replace(tzinfo=datetime.timezone.utc)
                    invitation_data['expires_at'] = expires_at
                except ValueError:
                    print(f"无法解析expires_at日期: {invitation_data['expires_at']}")
                    invitation_data['expires_at'] = now + datetime.timedelta(days=7)
            elif isinstance(invitation_data['expires_at'], datetime.datetime):
                # 如果已经是datetime对象但没有时区信息，添加UTC时区
                if invitation_data['expires_at'].tzinfo is None:
                    invitation_data['expires_at'] = invitation_data['expires_at'].replace(
                        tzinfo=datetime.timezone.utc
                    )
            
        # 生成唯一邀请码
        if 'invitation_code' not in invitation_data:
            invitation_data['invitation_code'] = str(uuid.uuid4()).replace('-', '')[:8]
            
        # 设置邀请类型和状态
        if 'type' not in invitation_data:
            invitation_data['type'] = 'edit'  # 默认为编辑权限
        if 'status' not in invitation_data:
            invitation_data['status'] = 'pending'  # 默认为待接受状态
            
        result = mongo.db[ShareInvitation.COLLECTION].insert_one(invitation_data)
        return result.inserted_id
    
    @staticmethod
    def get_invitation_by_id(mongo, invitation_id):
        """通过ID获取邀请"""
        try:
            object_id = ObjectId(invitation_id)
        except Exception:
            return None
            
        return mongo.db[ShareInvitation.COLLECTION].find_one({'_id': object_id})
    
    @staticmethod
    def get_invitation_by_code(mongo, invitation_code):
        """通过邀请码获取邀请"""
        return mongo.db[ShareInvitation.COLLECTION].find_one({'invitation_code': invitation_code})
    
    @staticmethod
    def get_invitations_by_trip(mongo, trip_id):
        """获取行程的所有邀请"""
        try:
            object_id = ObjectId(trip_id) if isinstance(trip_id, str) else trip_id
        except Exception:
            return []
            
        cursor = mongo.db[ShareInvitation.COLLECTION].find({'trip_id': object_id})
        return list(cursor)
    
    @staticmethod
    def update_invitation(mongo, invitation_id, update_data):
        """更新邀请状态"""
        if '_id' in update_data:
            del update_data['_id']
            
        result = mongo.db[ShareInvitation.COLLECTION].update_one(
            {'_id': ObjectId(invitation_id)},
            {'$set': update_data}
        )
        return result.modified_count > 0
    
    @staticmethod
    def accept_invitation(mongo, invitation_code, user_id, user_name, avatar_url=None):
        """接受邀请并将用户添加到行程成员中"""
        invitation = ShareInvitation.get_invitation_by_code(mongo, invitation_code)
        if not invitation:
            return False, "邀请不存在"
            
        # 检查邀请是否已过期
        now = datetime.datetime.now(datetime.timezone.utc)
        expires_at = invitation.get('expires_at')
        
        # 确保expires_at有时区信息
        if expires_at and expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=datetime.timezone.utc)
            
        if expires_at and expires_at < now:
            return False, "邀请已过期"
            
        # 检查邀请状态
        if invitation.get('status') != 'pending':
            return False, f"邀请状态为{invitation.get('status')}"
            
        # 更新邀请状态
        ShareInvitation.update_invitation(
            mongo, 
            invitation['_id'], 
            {
                'status': 'accepted',
                'invitee_user_id': user_id,
                'accepted_at': now
            }
        )
        
        # 将用户添加到行程成员中
        from .user_trip import UserTrip
        
        # 检查用户是否已经是成员
        trip = UserTrip.get_user_trip_by_id(mongo, invitation['trip_id'])
        if not trip:
            return False, "行程不存在"
            
        # 检查成员是否已存在
        for member in trip.get('members', []):
            if member.get('userId') == user_id:
                return True, "用户已经是成员"
                
        # 添加成员
        member_data = {
            "userId": user_id,
            "name": user_name,
            "avatarUrl": avatar_url or "",
            "role": invitation.get('type', 'edit')  # 使用邀请中的权限类型
        }
        
        UserTrip.add_member(mongo, invitation['trip_id'], member_data)
        return True, "成功加入行程"
    
    @staticmethod
    def reject_invitation(mongo, invitation_code):
        """拒绝邀请"""
        invitation = ShareInvitation.get_invitation_by_code(mongo, invitation_code)
        if not invitation:
            return False
            
        return ShareInvitation.update_invitation(
            mongo, 
            invitation['_id'], 
            {
                'status': 'rejected',
                'rejected_at': datetime.datetime.now(datetime.timezone.utc)
            }
        )
    
    @staticmethod
    def delete_invitation(mongo, invitation_id):
        """删除邀请"""
        result = mongo.db[ShareInvitation.COLLECTION].delete_one({'_id': ObjectId(invitation_id)})
        return result.deleted_count > 0
    
    @staticmethod
    def to_json(invitation_doc):
        """将MongoDB文档转换为JSON格式"""
        if not invitation_doc:
            return None
            
        # 使用工具函数处理ObjectId和日期
        invitation_json = parse_mongo_doc(invitation_doc)
        
        # 添加方便前端使用的字段
        invitation_json['share_link'] = f"/invite/{invitation_doc.get('invitation_code')}"
        
        # 正确处理日期时间比较
        now = datetime.datetime.now(datetime.timezone.utc)
        expires_at = invitation_doc.get('expires_at')
        
        if expires_at:
            # 确保expires_at是datetime对象
            if isinstance(expires_at, str):
                try:
                    expires_at = datetime.datetime.fromisoformat(expires_at.replace('Z', '+00:00'))
                except ValueError:
                    # 如果无法解析，则默认未过期
                    invitation_json['is_expired'] = False
                    return invitation_json
            
            # 确保比较的两个日期时间对象都有时区信息
            if expires_at.tzinfo is None:
                expires_at = expires_at.replace(tzinfo=datetime.timezone.utc)
                
            invitation_json['is_expired'] = expires_at < now
        else:
            invitation_json['is_expired'] = False
        
        return invitation_json 