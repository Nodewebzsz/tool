#!/bin/bash
# 添加一个用户, 该用户无用户管理权限, 只能管理实例、存储、网络
# 在 Cloud Shell 中执行
# 颜色
RED="\e[31m"
GREEN="\e[32m"
RESET="\e[0m"
# 参数
export compartment_id=""     # 租户OCID
export group_name="Group_for_Api_used"    # 组名称
export group_des="这个用户组是给api使用的,权限会受控,防止api操作用户类权限"    # 组描述
export policy_name="Policy_for_Api_used"   # 策略名称
export policy_des="这个策略是给api使用的,权限会受控,防止api操作用户类权限"    # 策略描述
export policy_file="file://statements.json" # 策略语句文件
export user_name="User_for_Api_used"    # 用户名称
export user_des="这个用户是给api使用的,权限会受控,防止api操作用户类权限"    # 用户描述
export user_email="xxxxxx@domain.com"   # 用户邮箱，当type为new时必填
export type="new"       # 控制面板类型，new或者old
export ignore_error="0"      # 忽略错误
while [[ $# -ge 1 ]]; do
 case $1 in
 -c | --compartment_id )
  shift
  compartment_id="$1"
  shift
  ;;
 -g | --group_name )
  shift
  group_name="$1"
  shift
  ;;
 -gd | --group_des )
  shift
  group_des="$1"
  shift
  ;;
 -p | --policy_name )
  shift
  policy_name="$1"
  shift
  ;;
 -pd | --policy_des )
  shift
  policy_des="$1"
  shift
  ;;
 -u | --user_name )
  shift
  user_name="$1"
  shift
  ;;
 -ud | --user_des )
  shift
  user_des="$1"
  shift
  ;;
 -ue | --user_email )
  shift
  user_email="$1"
  shift
  ;;
 -t | --type )
  shift
  type="$1"
  shift
  ;;
 --ignore_error )
  shift
  ignore_error="1"
  ;;
 -h | --help )
  echo -ne "Usage: bash $(basename $0) [options]\n\033[33m\033[04m-c\033[0m\t\t租户OCID, 默认自动获取\n\033[33m\033[04m-g\033[0m\t\t组名称, 默认Core-Admins\n\033[33m\033[04m-gd\033[0m\t\t组描述, 默认Core-Admins\n\033[33m\033[04m-p\033[0m\t\t策略名称, 默认Core-Admins\n\033[33m\033[04m-pd\033[0m\t\t策略描述, 默认Core-Admins\n\033[33m\033[04m-pf\033[0m\t\t策略语句文件, 默认file://statements.json\n\033[33m\033[04m-u\033[0m\t\t用户名称, 默认Core-Admin\n\033[33m\033[04m-ud\033[0m\t\t用户描述, 默认Core-Admin\n\033[33m\033[04m-ue\033[0m\t\t用户邮箱, 当type为new时必填, 默认xx@domain.sssss\n\033[33m\033[04m-t\033[0m\t\t控制面板类型, new或者old, 默认old\n\033[33m\033[04m--ignore_error\033[0m\t忽略错误返回信息\n\033[33m\033[04m-h\033[0m\t\t帮助\n\nExample: bash $(basename $0) -ue xx@xx.com -t new --ignore_error \n"
  exit 1;
  ;;
 * )
  echo -e "${RED}无效参数: $1${RESET}"
  exit 1;
  ;;
 esac
 done
# 检查参数
if [ "$type" == "new" ]; then
 if [ "$user_email" == "" ]; then
 echo -e "${RED}用户邮箱不能为空${RESET}"
 exit 1
 fi
fi
# 策略语句
if [ "$type" == "new" ]; then
 echo "[
 \"Allow group 'Default'/'$group_name' to manage instance-family in tenancy\",
 \"Allow group 'Default'/'$group_name' to manage volume-family in tenancy\",
 \"Allow group 'Default'/'$group_name' to manage virtual-network-family in tenancy\"
 ]" > statements.json
else 
 echo "[
 \"Allow group $group_name to manage instance-family in tenancy\",
 \"Allow group $group_name to manage volume-family in tenancy\",
 \"Allow group $group_name to manage virtual-network-family in tenancy\"
 ]" > statements.json
fi
# 检查命令执行结果
function check() {
 if echo "$1" | grep -q "ServiceError"; then
 err_msg=$(echo "$1" | sed -n 's/.*"message": "\(.*\)",/\1/p')
 echo -e "${RED}命令执行失败：$err_msg${RESET}"
 if [ "$ignore_error" == "0" ]; then
  exit 1
 fi
 else
 echo -e "${GREEN}$2${RESET}"
 fi
}
# 获取租户OCID
compartment_id=$(oci iam availability-domain list --query 'data[0]."compartment-id"' --raw-output)
echo -e "${GREEN}租户OCID: $compartment_id ${RESET}"
# 创建组
group_result=$(oci iam group create --compartment-id $compartment_id --name $group_name --description $group_des 2>&1)
check "$group_result" "组创建成功"
group_id=$(echo $group_result | jq -r '.data.id')
# 创建策略
policy_result=$(oci iam policy create --compartment-id $compartment_id --description $policy_des --name $policy_name --statements $policy_file 2>&1)
check "$policy_result" "策略创建成功"
# 创建用户
if [ "$user_email" == "" ]; then
 user_result=$(oci iam user create --name $user_name --description $user_des --compartment-id $compartment_id 2>&1)
else
 user_result=$(oci iam user create --name $user_name --description $user_des --compartment-id $compartment_id --email $user_email 2>&1)
fi
check "$user_result" "用户创建成功"
user_id=$(echo $user_result | jq -r '.data.id')
# 将用户添加到组
add_result=$(oci iam group add-user --group-id $group_id --user-id $user_id 2>&1)
check "$add_result" "用户添加到组成功\n\n后续可手动在用户 $user_name 中添加 API密钥 (无需登录该用户)"
